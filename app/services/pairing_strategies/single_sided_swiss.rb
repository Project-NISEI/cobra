# frozen_string_literal: true

module PairingStrategies
  class SingleSidedSwiss < Swiss
    def pair!
      super

      apply_sides!
    end

    def self.get_pairings(players)
      cached_data = Hash[players.map do |player|
        [
          player.id,
          {
            points: player.points,
            side_bias: player.side_bias,
            opponents: player.pairings.each_with_object({}) do |pairing, output|
              output[pairing.opponent_for(player).id] ||= []
              output[pairing.opponent_for(player).id] << pairing.side_for(player)
            end
          }
        ]
      end]

      SwissImplementation.pair(players.to_a) do |player1, player2|
        # handle logic if one of the players is the bye
        if [player1, player2].include?(SwissImplementation::Bye)
          real_player = [player1, player2].difference([SwissImplementation::Bye]).first

          # return nil (no pairing possible) if player has already received bye
          next nil if cached_data[real_player.id][:opponents].keys.include?(nil)

          next points_weight(cached_data[real_player.id][:points], -1)
        end

        # return nil (no pairing possible) if players have already played twice
        if cached_data[player1.id][:opponents].keys.include?(player2.id) && cached_data[player1.id][:opponents][player2.id].count >= 2
          next nil
        end

        preferred_side = preferred_player1_side(
          cached_data[player1.id][:side_bias],
          cached_data[player2.id][:side_bias]
        )
        # return nil (no pairing possible) if the sides would repeat the previous pairing
        if preferred_side && cached_data[player1.id][:opponents][player2.id] && cached_data[player1.id][:opponents][player2.id].include?(preferred_side)
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

    def apply_sides!
      round.pairings.non_bye.each do |pairing|
        preference = self.class.preferred_player1_side(pairing.player1.side_bias, pairing.player2.side_bias)
        pairing.update(side: :player1_is_runner) if preference == :runner
        pairing.update(side: :player1_is_corp) if preference == :corp
        pairing.update(side: %i[player1_is_corp player1_is_runner].sample) if preference.nil?
      end
    end
  end
end
