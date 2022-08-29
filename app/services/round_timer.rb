class RoundTimer
  attr_reader :round
  delegate :round_timer_activations, to: :round
  delegate :completed?, to: :round

  def initialize(round)
    @round = round
  end

  def start!
    round_timer_activations.create!
  end

  def show?
    round_timer_activations.count > 0 && !completed?
  end

end
