# frozen_string_literal: true

module PairingStrategies
  class Swiss < Base
    BYE_WINNER_SCORE = 6
    BYE_LOSER_SCORE = 0

    def pair!
      assign_byes!

      paired_players.each do |pairing|
        round.pairings.create(pairing_params(pairing))
      end

      apply_numbers!(PairingSorters::Ranked)
    end

    def self.get_pairings(players)
      SwissImplementation.pair(
        players,
        delta_key: :points,
        exclude_key: :unpairable_opponents
      )
    end

    private

    def assign_byes!
      players_with_byes.each do |player|
        round.pairings.create(
          player1: player,
          player2: nil,
          score1: BYE_WINNER_SCORE,
          score2: BYE_LOSER_SCORE
        )
      end
    end

    def paired_players
      if first_round?
        return @paired_players ||= players_to_pair.to_a.shuffle(random:).in_groups_of(2,
                                                                                      SwissImplementation::Bye)
      end
      return @paired_players ||= PairingStrategies::BigSwiss.new(stage, self.class).pair! if players.count > 60

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

      pairing[player_index] == SwissImplementation::Bye ? BYE_LOSER_SCORE : BYE_WINNER_SCORE
    end

    def apply_numbers!(sorter)
      sorter.sort(round.pairings.non_bye).each_with_index do |pairing, i|
        pairing.update(table_number: i + 1)
      end

      non_bye_tables = round.pairings.non_bye.count
      round.pairings.bye.each_with_index do |pairing, i|
        pairing.update(table_number: i + non_bye_tables + 1)
      end
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
  end
end
