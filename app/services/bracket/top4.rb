# frozen_string_literal: true

module Bracket
  class Top4 < Base
    game 1, seed(1), seed(4), round: 1, successor: 3, bracket_type: :upper
    game 2, seed(2), seed(3), round: 1, successor: 3, bracket_type: :upper

    game 3, winner(1), winner(2), round: 2, successor: 6, bracket_type: :upper
    game 4, loser(1), loser(2), round: 2, successor: 5, bracket_type: :lower

    game 5, loser(3), winner(4), round: 3, successor: 6, bracket_type: :lower

    game 6, winner(3), winner(5), round: 4, successor: 7, bracket_type: :upper

    game 7, winner(6), loser(6), round: 5, bracket_type: :upper

    STANDINGS = [
      [winner(7), winner_if_also_winner(6, 3)],
      [loser(7), loser_if_also_winner(6, 5)],
      loser(5),
      loser(4)
    ].freeze
  end
end
