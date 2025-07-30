# frozen_string_literal: true

module Bracket
  class Top16 < Base
    game 1, seed(1), seed(16), round: 1
    game 2, seed(8), seed(9), round: 1
    game 3, seed(5), seed(12), round: 1
    game 4, seed(4), seed(13), round: 1
    game 5, seed(3), seed(14), round: 1
    game 6, seed(6), seed(11), round: 1
    game 7, seed(7), seed(10), round: 1
    game 8, seed(2), seed(15), round: 1

    game 9, loser(1), loser(2), round: 2
    game 10, loser(3), loser(4), round: 2
    game 11, loser(5), loser(6), round: 2
    game 12, loser(7), loser(8), round: 2
    game 13, winner(1), winner(2), round: 2
    game 14, winner(3), winner(4), round: 2
    game 15, winner(5), winner(6), round: 2
    game 16, winner(7), winner(8), round: 2

    game 17, loser(16), winner(9), round: 3
    game 18, loser(15), winner(10), round: 3
    game 19, loser(14), winner(11), round: 3
    game 20, loser(13), winner(12), round: 3
    game 21, winner(13), winner(14), round: 3
    game 22, winner(15), winner(16), round: 3

    game 23, winner(17), winner(18), round: 4
    game 24, winner(19), winner(20), round: 4
    game 27, winner(21), winner(22), round: 4

    game 25, loser(21), winner(23), round: 5
    game 26, winner(24), loser(22), round: 5

    game 28, winner(25), winner(26), round: 6

    game 29, loser(27), winner(28), round: 7

    game 30, winner(27), winner(29), round: 8

    game 31, winner(30), loser(30), round: 9

    STANDINGS = [
      [winner(31), winner_if_also_winner(30, 27)],
      [loser(31), loser_if_also_winner(30, 29)],
      loser(29),
      loser(28),
      seed_of([loser(25), loser(26)], 1),
      seed_of([loser(25), loser(26)], 2),
      seed_of([loser(23), loser(24)], 1),
      seed_of([loser(23), loser(24)], 2),
      seed_of([loser(17), loser(18), loser(19), loser(20)], 1),
      seed_of([loser(17), loser(18), loser(19), loser(20)], 2),
      seed_of([loser(17), loser(18), loser(19), loser(20)], 3),
      seed_of([loser(17), loser(18), loser(19), loser(20)], 4),
      seed_of([loser(9), loser(10), loser(11), loser(12)], 1),
      seed_of([loser(9), loser(10), loser(11), loser(12)], 2),
      seed_of([loser(9), loser(10), loser(11), loser(12)], 3),
      seed_of([loser(9), loser(10), loser(11), loser(12)], 4)
    ].freeze

    SUCCESSOR_GAMES = {
      1 => 13,
      2 => 13,
      3 => 14,
      4 => 14,
      5 => 15,
      6 => 15,
      7 => 16,
      8 => 16,
      9 => 17,
      10 => 18,
      11 => 19,
      12 => 20,
      13 => 21,
      14 => 21,
      15 => 22,
      16 => 22,
      17 => 23,
      18 => 23,
      19 => 24,
      20 => 24,
      21 => 27,
      22 => 27,
      23 => 25,
      24 => 26,
      25 => 28,
      26 => 28,
      27 => 30,
      28 => 29,
      29 => 30,
      30 => 31
    }.freeze

    def self.bracket_type(game_number)
      return :lower if [9, 10, 11, 12, 17, 18, 19, 20, 23, 24, 25, 26, 28, 29].include? game_number

      :upper
    end

    def self.successor_game(game_number)
      SUCCESSOR_GAMES[game_number]
    end
  end
end
