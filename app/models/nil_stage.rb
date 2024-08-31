# frozen_string_literal: true

class NilStage
  def players
    Player.none
  end

  def standings
    []
  end

  def rounds
    Round.none
  end
end
