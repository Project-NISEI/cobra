# frozen_string_literal: true

module PairingStrategies
  class SingleSidedSwiss < Base
    def initialize(round, random = Random)
      super
      @bye_winner_score = 3
      @bye_loser_score = 0
      # @cached_data will hold a data structure for pairing information that is cheaper than the ActiveRecord objects.
      @cached_data = nil
    end

    def pair!
      assign_byes!

      paired_players.each do |pairing|
        round.pairings.create(pairing_params(pairing))
      end

      SwissTables.assign_table_numbers!(round.pairings)

      # Set player sides for the pairings.
      apply_sides!
    end

    def self.get_pairings(players, cached_data)
      SwissImplementation.pair(players.to_a) do |player1, player2|
        # handle logic if one of the players is the bye
        if [player1, player2].include?(SwissImplementation::Bye)
          real_player = [player1, player2].difference([SwissImplementation::Bye]).first

          # return nil (no pairing possible) if player has already received bye
          next nil if cached_data[real_player.id][:opponents].keys.include?(nil)

          next points_weight(cached_data[real_player.id][:points], -1)
        end

        # return nil (no pairing possible) if players have already played twice
        if cached_data[player1.id][:opponents].keys.include?(player2.id) &&
           cached_data[player1.id][:opponents][player2.id].count >= 2
          next nil
        end

        preferred_side = preferred_player1_side(
          cached_data[player1.id][:side_bias],
          cached_data[player2.id][:side_bias]
        )
        # return nil (no pairing possible) if the sides would repeat the previous pairing
        if preferred_side && cached_data[player1.id][:opponents][player2.id] &&
           cached_data[player1.id][:opponents][player2.id].include?(preferred_side)
          next nil
        end

        points_weight(cached_data[player1.id][:points], cached_data[player2.id][:points]) +
          side_bias_weight(cached_data[player1.id][:side_bias], cached_data[player2.id][:side_bias]) +
          rematch_bias_weight(cached_data[player1.id][:opponents].keys.include?(player2.id))
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

    def nilToZero(val)
      val.nil? ? 0 : val
    end

    def maybe_build_cached_data
      return unless @cached_data.nil?

      @cached_data = {}
      # puts "Populating @cached_data for tournament_id #{round.stage.tournament_id}"
      # TODO: optimize away the indirection to get tournament id
      player_summary = ActiveRecord::Base.connection.select_all("
          SELECT
            p.id,
            p.side,
            p.player1_id,
            COALESCE(p.score1, 0) AS score1,
            p.player2_id,
            COALESCE(p.score2, 0) AS score2
          FROM
            pairings AS p
            INNER JOIN rounds AS r ON p.round_id = r.id
            INNER JOIN stages AS s ON r.stage_id = s.id
          WHERE s.tournament_id = #{@round.stage.tournament_id}")

      # puts "player_summary.length is #{player_summary.length}"
      player_summary.each do |p|
        # %w[player1_id player2_id].each do |pk|
        # Initialize entries for each player if missing.
        player1 = p['player1_id']
        player2 = p['player2_id']
        score1 = nilToZero(p['score1'])
        score2 = nilToZero(p['score2'])

        if !player1.nil? && !@cached_data.key?(player1)
          @cached_data[player1] = { points: 0, side_bias: 0, opponents: {} }
        end
        if !player2.nil? && !@cached_data.key?(player2)
          @cached_data[player2] = { points: 0, side_bias: 0, opponents: {} }
        end

        @cached_data[player1][:points] += score1 unless player1.nil?
        @cached_data[player2][:points] += score2 unless player2.nil?

        # Set side bias
        if p['side'] == 1
          @cached_data[player1][:side_bias] += 1
          @cached_data[player2][:side_bias] -= 1
        elsif p['side'] == 2
          @cached_data[player2][:side_bias] += 1
          @cached_data[player1][:side_bias] -= 1
        end

        # Set side if not a bye. For a bye, set side to nil.
        player1_side = if player1.nil?
                         nil
                       else
                         (p['side'] == :player1_is_corp ? :corp : :runner)
                       end
        player2_side = if player2.nil?
                         nil
                       else
                         (p['side'] == :player1_is_corp ? :runner : :corp)
                       end

        unless player1.nil?
          @cached_data[player1][:opponents][player2] = [] unless @cached_data[player1][:opponents].key?(player2)
          @cached_data[player1][:opponents][player2] << player2_side
        end

        unless player2.nil? # rubocop:disable Style/Next
          opponents = @cached_data[player2][:opponents]
          opponents[player1] = [] unless opponents.key?(player1)
          opponents[player1] << player1_side
        end
      end
      # puts 'Done populating @cached_data'
      # puts @cached_data
    end

    def assign_byes!
      players_with_byes.each do |player|
        round.pairings.create(
          player1: player,
          player2: nil,
          score1: @bye_winner_score,
          score2: @bye_loser_score
        )
      end
    end

    def paired_players
      if first_round?
        return @paired_players ||= players_to_pair.to_a.shuffle(random:).in_groups_of(2,
                                                                                      SwissImplementation::Bye)
      end

      maybe_build_cached_data
      @paired_players ||= self.class.get_pairings(players_to_pair.to_a, @cached_data)
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
      return players.with_first_round_bye if first_round?

      []
    end

    def players_to_pair
      @players_to_pair ||= players - players_with_byes
    end

    def first_round?
      (stage.rounds - [round]).empty?
    end

    def apply_sides!
      maybe_build_cached_data
      round.pairings.non_bye.each do |pairing|
        preference = self.class.preferred_player1_side(
          @cached_data[pairing.player1_id].nil? ? 0 : @cached_data[pairing.player1_id][:side_bias],
          @cached_data[pairing.player2_id].nil? ? 0 : @cached_data[pairing.player2_id][:side_bias]
        )
        pairing.update(side: :player1_is_runner) if preference == :runner
        pairing.update(side: :player1_is_corp) if preference == :corp
        pairing.update(side: %i[player1_is_corp player1_is_runner].sample) if preference.nil?
      end
    end
  end
end
