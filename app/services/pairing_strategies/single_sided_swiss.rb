module PairingStrategies
  class SingleSidedSwiss < Swiss
    def pair!
      super

      apply_sides!
    end

    def paired_players
      return @paired_players ||= players_to_pair.to_a.shuffle(random: random).in_groups_of(2, SwissImplementation::Bye) if first_round?
      # return @paired_players ||= PairingStrategies::BigSwiss.new(stage).pair! if players.count > 60

      @paired_players ||= SwissImplementation.pair(players_to_pair.to_a) do |player1, player2|
        # handle logic if one of the players is the bye
        if [player1, player2].include?(SwissImplementation::Bye)
          real_player = [player1, player2].difference([SwissImplementation::Bye]).first

          # return nil (no pairing possible) if player has already received bye
          next nil if Pairing.for_players(real_player, nil).any?

          next points_weight(real_player, SwissImplementation::Bye)
        end

        # return nil (no pairing possible) if players have already played twice
        next nil if Pairing.for_players(player1, player2).count >= 2

        preferred_side = preferred_player1_side(player1, player2)
        previous_pairing = Pairing.for_players(player1, player2).last
        # return nil (no pairing possible) if the sides would repeat the previous pairing
        next nil if previous_pairing && preferred_side && previous_pairing.side_for(player1) == preferred_side

        points_weight(player1, player2) + side_bias_weight(player1, player2) + rematch_bias_weight(player1, player2)
      end
    end

    def points_weight(player1, player2)
      0 - (points_for(player1) - points_for(player2)) ** 2 / 6.0
    end

    def side_bias_weight(player1, player2)
      8 ** ((player1.side_bias - player2.side_bias).abs / 2.0)
    end

    def rematch_bias_weight(player1, player2)
      0 - Pairing.for_players(player1, player2).count/2.0
    end

    def preferred_player1_side(player1, player2)
      bias = player1.side_bias - player2.side_bias
      return :runner if bias > 0
      return :corp if bias < 0

      nil
    end

    private

    def points_for(player)
      return -1 if player == SwissImplementation::Bye

      player.points
    end

    def apply_sides!
      round.pairings.non_bye.each do |pairing|
        preference = preferred_player1_side(pairing.player1, pairing.player2)
        pairing.update(side: :player1_is_runner) if preference == :runner
        pairing.update(side: :player1_is_corp) if preference == :corp
        pairing.update(side: [:player1_is_corp, :player1_is_runner].sample) if preference == nil
      end
    end
  end
end
