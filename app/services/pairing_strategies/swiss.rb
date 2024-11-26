# frozen_string_literal: true

module PairingStrategies
  class Swiss < Base
    def initialize(round, random = Random)
      super
      @bye_winner_score = 6
      @bye_loser_score = 0

      @thin_pairings = []
    end

    def pair!
      assign_byes!

      paired_players.each do |pairing|
        pp = pairing_params(pairing)
        @thin_pairings << PlainPairing.new(pp[:player1], pp[:score1], pp[:player2], pp[:score2])
      end

      SwissTables.assign_table_numbers!(@thin_pairings)

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

          p.save
        end
      end
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
      players_with_byes.each_key do |player_id|
        @thin_pairings << PlainPairing.new(@players[player_id], @bye_winner_score, nil, @bye_loser_score)
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
  end
end
