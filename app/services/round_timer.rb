class RoundTimer

  def initialize(round)
    @round = round
  end

  def start!
    round_timer_activations.create! start_time: Time.current
  end

  def stop!
    round_timer_activations.last.update(stop_time: Time.current)
  end

  def reset!
    round_timer_activations.destroy_all
  end

  def show?
    round_timer_activations.count > 0 && !completed?
  end

  def paused?
    last = round_timer_activations.last
    !last.nil? && !last.stop_time.nil? && last.stop_time < expected_end
  end

  def finish_time
    last = round_timer_activations.last
    if !last.nil? && (last.stop_time.nil? || last.stop_time >= expected_end)
      expected_end
    else
      nil
    end
  end

  def running?
    last = round_timer_activations.last
    if last.nil? || !last.stop_time.nil?
      false
    else
      Time.zone.now < expected_end
    end
  end

  def state
    State.new(finish_time, paused?)
  end

  private

  State = Struct.new(:finish_time, :paused)
  attr_reader :round
  delegate :round_timer_activations, to: :round
  delegate :completed?, to: :round
  delegate :length_minutes, to: :round

  def expected_end
    last = round_timer_activations.last
    unless last.nil?
      last.start_time + length_minutes*60 - committed_seconds
    end
  end

  def committed_seconds
    time = 0
    (0...round_timer_activations.size - 1).each do |index|
      time += round_timer_activations[index].committed_seconds
    end
    time
  end

end