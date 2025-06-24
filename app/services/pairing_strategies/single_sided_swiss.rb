# frozen_string_literal: true

module PairingStrategies
  class SingleSidedSwiss < Base
    CORP = 1
    RUNNER = 2

    def initialize(round, random = Random)
      super
      @bye_winner_score = 3
      @bye_loser_score = 0

      @plain_pairings = []
    end

    def pair!
      assign_byes!

      paired_players.each do |pairing|
        pp = pairing_params(pairing)
        @plain_pairings << PlainPairing.new(pp[:player1], pp[:score1], pp[:player2], pp[:score2])
      end

      SwissTables.assign_table_numbers!(@plain_pairings)

      # Set player sides for the pairings.
      apply_sides!

      ActiveRecord::Base.transaction do
        @plain_pairings.each do |pp|
          p = Pairing.new(round:, player1_id: pp.player1&.id, player2_id: pp.player2&.id, table_number: pp.table_number)
          if pp.bye?
            if pp.player1.nil?
              p.score2 = @bye_winner_score
            else
              p.score1 = @bye_winner_score
            end
          end
          # Don't set a side for byes.
          unless pp.bye?
            p.side = pp.player1_side == 'corp' ? CORP : RUNNER
          end

          p.save
        end
      end
    end

    def self.get_pairings(players)
      SwissImplementation.pair(players) do |player1, player2|
        # handle logic if one of the players is the bye
        if [player1, player2].include?(SwissImplementation::Bye)
          real_player = [player1, player2].difference([SwissImplementation::Bye]).first

          # return nil (no pairing possible) if player has already received bye
          next nil if real_player.had_bye

          next points_weight(real_player.points, -1)
        end

        # return nil (no pairing possible) if players have already played twice
        next nil if player1.opponents.key?(player2.id) && player1.opponents[player2.id].count >= 2

        # Check if either player has a preferred side bias.
        preferred_side = preferred_player1_side(player1.side_bias, player2.side_bias)

        # return nil (no pairing possible) if there is a side bias and the sides would repeat the previous pairing
        if preferred_side && player1.opponents[player2.id] &&
           player1.opponents[player2.id].include?(preferred_side)
          next nil
        end

        weight =
          points_weight(player1.points, player2.points) +
          side_bias_weight(player1.side_bias, player2.side_bias) +
          rematch_bias_weight(player1.opponents.keys.include?(player2.id))

        weight = 1000 - weight if ENV['AESOPS_LOGIC']

        weight
      end
    end

    def self.points_weight(player1_points, player2_points)
      if ENV['AESOPS_LOGIC']
        return ((player1_points - player2_points + 1) * (player1_points - player2_points)).abs / 6.0
      end

      0 - (player1_points - player2_points)**2 / 6.0
    end

    def self.side_bias_weight(player1_side_bias, player2_side_bias)
      return 8**[(player1_side_bias + 1).abs, (player2_side_bias - 1).abs].max.abs if ENV['AESOPS_LOGIC']

      8**((player1_side_bias - player2_side_bias).abs / 2.0)
    end

    def self.rematch_bias_weight(has_previous_matchup)
      return has_previous_matchup ? 0.1 : 0 if ENV['AESOPS_LOGIC']

      has_previous_matchup ? -0.5 : 0
    end

    def self.preferred_player1_side(player1_side_bias, player2_side_bias)
      return :runner if player1_side_bias > player2_side_bias
      return :corp if player1_side_bias < player2_side_bias

      nil
    end

    private

    def assign_byes!
      players_with_byes.each do |player|
        # player[0] is the player id from the player summary structure
        @plain_pairings << PlainPairing.new(@players[player[0]], @bye_winner_score, nil, @bye_loser_score)
      end
    end

    def paired_players
      if first_round?
        @paired_players ||= players_to_pair.shuffle(random:).in_groups_of(2, nil)
        return @paired_players
      end

      @paired_players ||= self.class.get_pairings(players_to_pair)
    end

    def pairing_params(pairing)
      {
        player1: player_from_pairing(pairing[0]),
        player2: player_from_pairing(pairing[1]),
        score1: auto_score(pairing, 0),
        score2: auto_score(pairing, 1)
      }
    end

    def player_from_pairing(player)
      player == SwissImplementation::Bye ? nil : player
    end

    def auto_score(pairing, player_index)
      return unless pairing[0] == SwissImplementation::Bye || pairing[1] == SwissImplementation::Bye

      pairing[player_index] == SwissImplementation::Bye ? @bye_loser_score : @bye_winner_score
    end

    def players_with_byes
      return players.select { |_, v| v.first_round_bye } if first_round?

      {}
    end

    def players_to_pair
      @players_to_pair ||= players.filter_map { |k, v| v unless players_with_byes.key?(k) }.to_a.sort_by(&:id)
    end

    def first_round?
      (stage.rounds - [round]).empty?
    end

    def apply_sides!
      @plain_pairings.each do |pairing|
        next if pairing.bye?

        preference = self.class.preferred_player1_side(pairing.player1.side_bias, pairing.player2.side_bias)
        if preference.nil? && pairing.player1.opponents.key?(pairing.player2.id)
          # Pick the opposite side if this is a repeat matchup for these players.
          pairing.player1_side = pairing.player1.opponents[pairing.player2.id].first == 'corp' ? 'runner' : 'corp'
        elsif !preference.nil?
          pairing.player1_side = 'runner' if preference == :runner
          pairing.player1_side = 'corp' if preference == :corp
        elsif preference.nil?
          # Fall back to random assignment
          pairing.player1_side = %w[corp runner].sample
        end
      end
    end
  end
end
