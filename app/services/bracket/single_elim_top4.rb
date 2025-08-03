# frozen_string_literal: true

module Bracket
  class SingleElimTop4 < Base
    game 1, seed(1), seed(4), round: 1
    game 2, seed(2), seed(3), round: 1

    game 3, seed_of([winner(1), winner(2)], 1), seed_of([winner(1), winner(2)], 2), round: 2

    STANDINGS = [
      winner(3),
      loser(3),
      seed_of([loser(1), loser(2)], 1),
      seed_of([loser(1), loser(2)], 2)
    ].freeze

    SUCCESSOR_GAMES = {
      1 => 3,
      2 => 3
    }.freeze

    def self.successor_game(game_number)
      SUCCESSOR_GAMES[game_number]
    end
  end
end
