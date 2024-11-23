# frozen_string_literal: true

module PairingStrategies
  class SingleSidedSwiss < Base
    def initialize(round, random = Random)
      super
      @bye_winner_score = 3
      @bye_loser_score = 0

      @thin_pairings = []
    end

    def pair!
      assign_byes!

      paired_players.each do |pairing|
        pp = pairing_params(pairing)
        @thin_pairings << ThinPairing.new(pp[:player1], pp[:score1], pp[:player2], pp[:score2])
      end

      SwissTables.assign_table_numbers!(@thin_pairings)

      # Set player sides for the pairings.
      apply_sides!

      ActiveRecord::Base.transaction do
        @thin_pairings.each do |tp|
          p = Pairing.new(round:, player1_id: tp.player1&.id, player2_id: tp.player2&.id, table_number: tp.table_number)
          if tp.bye?
            if tp.player1.nil?
              p.score2 = @bye_winner_score
            else
              p.score1 = @bye_winner_score
            end
          end
          # Don't set a side for byes.
          unless tp.bye?
            # TODO(plural): Make some better enums available.
            p.side = tp.player1_side == 'corp' ? 1 : 2
          end

          p.save
        end
      end
    end

    def self.get_pairings(players)
      SwissImplementation.pair(players.to_a) do |player1, player2|
        # handle logic if one of the players is the bye
        if [player1, player2].include?(SwissImplementation::Bye)
          real_player = [player1, player2].difference([SwissImplementation::Bye]).first

          # return nil (no pairing possible) if player has already received bye
          # TODO(plural): Handle the "had a bye" use case more deliberately and probably correctly.
          next nil if real_player.had_bye # real_player.opponents.keys.include?(nil)

          next points_weight(real_player.points, -1)
        end

        # return nil (no pairing possible) if players have already played twice
        next nil if player1.opponents.key?(player2.id) && player1.opponents[player2.id].count >= 2

        preferred_side = preferred_player1_side(player1.side_bias, player2.side_bias)

        # return nil (no pairing possible) if the sides would repeat the previous pairing
        if preferred_side && player1.opponents[player2.id] &&
           player1.opponents[player2.id].include?(preferred_side)
          next nil
        end

        points_weight(player1.points, player2.points) +
          side_bias_weight(player1.side_bias, player2.side_bias) +
          rematch_bias_weight(player1.opponents.keys.include?(player2.id))
      end
    end

    def self.points_weight(player1_points, player2_points)
      0 - (player1_points - player2_points)**2 / 6.0
    end

    def self.side_bias_weight(player1_side_bias, player2_side_bias)
      8**((player1_side_bias - player2_side_bias).abs / 2.0)
    end

    def self.rematch_bias_weight(has_previous_matchup)
      return -0.5 if has_previous_matchup

      0
    end

    def self.preferred_player1_side(player1_side_bias, player2_side_bias)
      return :runner if player1_side_bias > player2_side_bias
      return :corp if player1_side_bias < player2_side_bias

      nil
    end

    private

    def assign_byes!
      players_with_byes.each do |player|
        @thin_pairings << ThinPairing.new(@players[player.id], @bye_winner_score, nil, @bye_loser_score)
      end
    end

    def paired_players
      if first_round?
        @paired_players ||= players_to_pair.to_a.shuffle(random:).in_groups_of(2,
                                                                               nil)
        return @paired_players
      end

      @paired_players ||= self.class.get_pairings(players_to_pair.to_a)
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
      @players_to_pair ||= players.filter_map { |k, v| v unless players_with_byes.key?(k) }
    end

    def first_round?
      (stage.rounds - [round]).empty?
    end

    def apply_sides!
      @thin_pairings.each do |pairing|
        next if pairing.bye?

        preference = self.class.preferred_player1_side(pairing.player1.side_bias, pairing.player2.side_bias)
        pairing.player1_side = 'runner' if preference == :runner
        pairing.player1_side = 'corp' if preference == :corp
        pairing.player1_side = %w[corp runner].sample if preference.nil?
      end
    end
  end
end
