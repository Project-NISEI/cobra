class RoundTimer
  attr_reader :round
  delegate :round_timer_activations, to: :round
  delegate :completed?, to: :round
  delegate :length_minutes, to: :round

  def initialize(round)
    @round = round
  end

  def start!
    round_timer_activations.create! start_time: Time.current
  end

  def show?
    round_timer_activations.count > 0 && !completed?
  end

  def finish_time
    round_timer_activations.last.start_time + length_minutes.minutes
  end

end
