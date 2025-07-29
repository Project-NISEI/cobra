# frozen_string_literal: true

# TODO(plural): Add debug level logging to the pairings class to allow dumping details out.
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
      assign_first_round_byes!

      # paired_players will invoke the pairing logic and eventually evaluate all potential pairings.
      paired_players.each do |pairing|
        pp = pairing_params(pairing)
        @plain_pairings << PlainPairing.new(pp[:player1], pp[:score1], pp[:player2], pp[:score2])
      end

      SwissTables.assign_table_numbers!(@plain_pairings)

      # Set player sides for the pairings.
      apply_sides!

      # Write the results to the database.
      ActiveRecord::Base.transaction do
        @plain_pairings.each do |pp|
          p = Pairing.new(round:, player1_id: pp.player1&.id, player2_id: pp.player2&.id, table_number: pp.table_number)
          # Assign scores for byes.
          if pp.bye?
            if pp.player1.nil?
              p.score2 = @bye_winner_score
            else
              p.score1 = @bye_winner_score
            end
          else
            # Assign sides for non-bye pairings.
            p.side = pp.player1_side == 'corp' ? CORP : RUNNER
          end

          p.save
        end
      end
    end

    def self.calculate_pairings(players)
      # The block argument to SwissImplementation.pair is invoked for each potential pairing of players
      # and will return the calculated weight for that potential pairing.
      SwissImplementation.pair(players) do |player1, player2|
        next potential_pairing_weight(player1, player2)
      end
    end

    def self.potential_pairing_weight(player1, player2)
      # Potential bye pairing.
      if [player1, player2].include?(SwissImplementation::Bye)
        real_player = [player1, player2].difference([SwissImplementation::Bye]).first

        # return nil (no pairing possible) if player has already received bye
        return nil if real_player.had_bye

        return 1000 - points_weight(real_player.points, -1)
      end

      # return nil (no pairing possible) if players have already played twice
      # TODO(plural): Start here for investigating lucille's bug with 3 matchups.
      return nil if player1.opponents.key?(player2.id) && player1.opponents[player2.id].count >= 2

      # Check if either player has a preferred side bias.
      preferred_side = preferred_player1_side(player1.side_bias, player2.side_bias)

      # return nil (no pairing possible) if there is a side bias and the sides would repeat the previous pairing
      return nil if preferred_side && player1.opponents[player2.id]&.include?(preferred_side)

      # Points and Rematch weights aren't affected by sides so we only need to calculate them once.
      points = points_weight(player1.points, player2.points)
      rematch = rematch_bias_weight(player1.opponents.keys.include?(player2.id))

      legal_options = self.legal_options(player1, player2)

      min_cost = 1000
      # Player 1 can corp
      if legal_options[0]
        min_cost = [points + rematch + side_bias_weight(player1.side_bias, player2.side_bias), min_cost].min
      end
      # Player 2 can corp
      if legal_options[1]
        min_cost = [points + rematch + side_bias_weight(player2.side_bias, player1.side_bias), min_cost].min
      end

      return nil if min_cost >= 100

      1000 - min_cost
    end

    # The weight is calculated as the square of the difference in points.
    # Points weight does not care about sides.
    def self.points_weight(player1_points, player2_points)
      (player1_points - player2_points)**2
    end

    def self.side_bias_weight(player1_side_bias, player2_side_bias)
      50**[[player1_side_bias, 0].max.abs, [player2_side_bias, 0].min.abs].max.abs
    end

    # The rematch penalty is applied if the players have played each other before.
    def self.rematch_bias_weight(has_previous_matchup)
      has_previous_matchup ? 5 : 0
    end

    def self.preferred_player1_side(player1_side_bias, player2_side_bias)
      return :runner if player1_side_bias > player2_side_bias
      return :corp if player1_side_bias < player2_side_bias

      nil
    end

    # Return an array of 2 booleans, representing whether there is a valid pairing for each player to play as Corp.
    def self.legal_options(player1, player2)
      player1_can_corp = true
      player2_can_corp = true
      player1_can_corp = false if player1.opponents.key?(player2.id) && player1.opponents[player2.id].first == 'corp'
      player2_can_corp = false if player2.opponents.key?(player1.id) && player2.opponents[player1.id].first == 'corp'

      [player1_can_corp, player2_can_corp]
    end

    def self.assign_side(player1, player2, random: Random)
      # If there was a prior matchup between these two players, we can only asside the missing matchup.
      if player1.opponents.key?(player2.id)
        if player1.opponents[player2.id].count == 2
          # This should not happen given the pairing logic will return nil for a double matchup,
          # but be defensive here because this happens after pairings are filtered by weight.
          Rails.logger.error "Tried to assign side for players #{player1.name} and #{player2.name} who have already played twice." # rubocop:disable Layout/LineLength
          return nil
        end

        return player1.opponents[player2.id].first == 'corp' ? 'runner' : 'corp'
      end

      # Honor any side bias next.
      preference = preferred_player1_side(player1.side_bias, player2.side_bias)

      return preference == :corp ? 'corp' : 'runner' unless preference.nil?

      # Fall back to random assignment if these players are balanced and have not yet played.
      %w[corp runner].sample(random: random)
    end

    private

    def assign_first_round_byes!
      players_with_byes.each do |player|
        # player[0] is the player id from the player summary structure
        @plain_pairings << PlainPairing.new(@players[player[0]], @bye_winner_score, nil, @bye_loser_score)
      end
    end

    def paired_players
      # The first round is simple: Pair off the eligible players randomly.
      # players_to_pair will not return players with byes
      if first_round?
        @paired_players ||= players_to_pair.shuffle(random:).in_groups_of(2, nil)
        return @paired_players
      end

      @paired_players ||= self.class.calculate_pairings(players_to_pair)
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

        pairing.player1_side = self.class.assign_side(pairing.player1, pairing.player2)
      end
    end
  end
end
