# frozen_string_literal: true

module Bracket
  class SingleElimTop16 < Base
    game 1, seed(1), seed(16), round: 1
    game 2, seed(2), seed(15), round: 1
    game 3, seed(3), seed(14), round: 1
    game 4, seed(4), seed(13), round: 1
    game 5, seed(5), seed(12), round: 1
    game 6, seed(6), seed(11), round: 1
    game 7, seed(7), seed(10), round: 1
    game 8, seed(8), seed(9), round: 1

    game 9,
         seed_of([winner(1), winner(2), winner(3), winner(4), winner(5), winner(6), winner(7), winner(8)], 1),
         seed_of([winner(1), winner(2), winner(3), winner(4), winner(5), winner(6), winner(7), winner(8)], 8),
         round: 2
    game 10,
         seed_of([winner(1), winner(2), winner(3), winner(4), winner(5), winner(6), winner(7), winner(8)], 2),
         seed_of([winner(1), winner(2), winner(3), winner(4), winner(5), winner(6), winner(7), winner(8)], 7),
         round: 2
    game 11,
         seed_of([winner(1), winner(2), winner(3), winner(4), winner(5), winner(6), winner(7), winner(8)], 3),
         seed_of([winner(1), winner(2), winner(3), winner(4), winner(5), winner(6), winner(7), winner(8)], 6),
         round: 2
    game 12,
         seed_of([winner(1), winner(2), winner(3), winner(4), winner(5), winner(6), winner(7), winner(8)], 4),
         seed_of([winner(1), winner(2), winner(3), winner(4), winner(5), winner(6), winner(7), winner(8)], 5),
         round: 2

    game 13,
         seed_of([winner(9), winner(10), winner(11), winner(12)], 1),
         seed_of([winner(9), winner(10), winner(11), winner(12)], 4),
         round: 3
    game 14,
         seed_of([winner(9), winner(10), winner(11), winner(12)], 2),
         seed_of([winner(9), winner(10), winner(11), winner(12)], 3),
         round: 3

    game 15, seed_of([winner(13), winner(14)], 1), seed_of([winner(13), winner(14)], 2), round: 4

    STANDINGS = [
      winner(15),
      loser(15),
      seed_of([loser(13), loser(14)], 1),
      seed_of([loser(13), loser(14)], 2),
      seed_of([loser(9), loser(10), loser(11), loser(12)], 1),
      seed_of([loser(9), loser(10), loser(11), loser(12)], 2),
      seed_of([loser(9), loser(10), loser(11), loser(12)], 3),
      seed_of([loser(9), loser(10), loser(11), loser(12)], 4),
      seed_of([loser(1), loser(2), loser(3), loser(4), loser(5), loser(6), loser(7), loser(8)], 1),
      seed_of([loser(1), loser(2), loser(3), loser(4), loser(5), loser(6), loser(7), loser(8)], 2),
      seed_of([loser(1), loser(2), loser(3), loser(4), loser(5), loser(6), loser(7), loser(8)], 3),
      seed_of([loser(1), loser(2), loser(3), loser(4), loser(5), loser(6), loser(7), loser(8)], 4),
      seed_of([loser(1), loser(2), loser(3), loser(4), loser(5), loser(6), loser(7), loser(8)], 5),
      seed_of([loser(1), loser(2), loser(3), loser(4), loser(5), loser(6), loser(7), loser(8)], 6),
      seed_of([loser(1), loser(2), loser(3), loser(4), loser(5), loser(6), loser(7), loser(8)], 7),
      seed_of([loser(1), loser(2), loser(3), loser(4), loser(5), loser(6), loser(7), loser(8)], 8)
    ].freeze

    UPPER_BRACKET = [*1..15].freeze

    SUCCESSOR_GAMES = {
      1 => 9,
      2 => 9,
      3 => 10,
      4 => 10,
      5 => 11,
      6 => 11,
      7 => 12,
      8 => 12,
      9 => 13,
      10 => 13,
      11 => 14,
      12 => 14,
      13 => 15,
      14 => 15
    }.freeze

    def self.upper_bracket
      UPPER_BRACKET
    end

    def self.successor_games
      SUCCESSOR_GAMES
    end
  end
end
