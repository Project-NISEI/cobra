# frozen_string_literal: true

module Bracket
  class SingleElimTop3 < Base
    game 1, seed(2), seed(3), round: 1, successor: 2, bracket_type: :upper

    game 2, seed(1), winner(1), round: 2, bracket_type: :upper

    STANDINGS = [
      winner(2),
      loser(2),
      loser(1)
    ].freeze
  end
end
