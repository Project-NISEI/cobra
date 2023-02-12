module Bracket
    class Top3 < Base
      game 1, seed(2), seed(3), round: 1

      game 2, seed(1), winner(1), round: 2
  
      STANDINGS = [
        winner(2),
        loser(2),
        loser(1)
      ]
    end
  end
