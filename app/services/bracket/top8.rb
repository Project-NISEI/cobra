# frozen_string_literal: true

module Bracket
  class Top8 < Base
    game 1, seed(1), seed(8), round: 1, successor: 5, bracket_type: :upper
    game 2, seed(4), seed(5), round: 1, successor: 5, bracket_type: :upper
    game 3, seed(2), seed(7), round: 1, successor: 6, bracket_type: :upper
    game 4, seed(3), seed(6), round: 1, successor: 6, bracket_type: :upper

    game 5, winner(1), winner(2), round: 2, successor: 9, bracket_type: :upper
    game 6, winner(3), winner(4), round: 2, successor: 9, bracket_type: :upper
    game 7, loser(1), loser(2), round: 2, successor: 10, bracket_type: :lower
    game 8, loser(3), loser(4), round: 2, successor: 11, bracket_type: :lower

    game 9, winner(5), winner(6), round: 3, successor: 14, bracket_type: :upper
    game 10, loser(6), winner(7), round: 3, successor: 12, bracket_type: :lower
    game 11, winner(8), loser(5), round: 3, successor: 12, bracket_type: :lower

    game 12, winner(10), winner(11), round: 4, successor: 13, bracket_type: :lower

    game 13, loser(9), winner(12), round: 5, successor: 14, bracket_type: :lower

    game 14, winner(9), winner(13), round: 6, successor: 15, bracket_type: :upper

    game 15, winner(14), loser(14), round: 7, bracket_type: :upper

    STANDINGS = [
      [winner(15), winner_if_also_winner(14, 9)],
      [loser(15), loser_if_also_winner(14, 13)],
      loser(13),
      loser(12),
      seed_of([loser(10), loser(11)], 1),
      seed_of([loser(10), loser(11)], 2),
      seed_of([loser(7), loser(8)], 1),
      seed_of([loser(7), loser(8)], 2)
    ].freeze
  end
end
