# frozen_string_literal: true

module Bracket
  class SingleElimTop8 < Base
    game 1, seed(1), seed(8), round: 1, successor: 5, bracket_type: :upper
    game 2, seed(2), seed(7), round: 1, successor: 5, bracket_type: :upper
    game 3, seed(3), seed(6), round: 1, successor: 6, bracket_type: :upper
    game 4, seed(4), seed(5), round: 1, successor: 6, bracket_type: :upper

    game 5, seed_of([winner(1), winner(2), winner(3), winner(4)], 1),
         seed_of([winner(1), winner(2), winner(3), winner(4)], 4), round: 2, successor: 7, bracket_type: :upper
    game 6, seed_of([winner(1), winner(2), winner(3), winner(4)], 2),
         seed_of([winner(1), winner(2), winner(3), winner(4)], 3), round: 2, successor: 7, bracket_type: :upper

    game 7, seed_of([winner(5), winner(6)], 1), seed_of([winner(5), winner(6)], 2), round: 3, bracket_type: :upper

    STANDINGS = [
      winner(7),
      loser(7),
      seed_of([loser(5), loser(6)], 1),
      seed_of([loser(5), loser(6)], 2),
      seed_of([loser(1), loser(2), loser(3), loser(4)], 1),
      seed_of([loser(1), loser(2), loser(3), loser(4)], 2),
      seed_of([loser(1), loser(2), loser(3), loser(4)], 3),
      seed_of([loser(1), loser(2), loser(3), loser(4)], 4)
    ].freeze
  end
end
