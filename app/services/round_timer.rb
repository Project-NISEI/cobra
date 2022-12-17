class RoundTimer

  def initialize(round)
    @round = round
  end

  def start!
    round_timer_activations.create! start_time: Time.current
  end

  def stop!
    round_timer_activations.last&.update(stop_time: Time.current)
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

  def running?
    last = round_timer_activations.last
    if last.nil? || !last.stop_time.nil?
      false
    else
      Time.zone.now < expected_end
    end
  end

  def started?
    !round_timer_activations.last.nil?
  end

  def state
    if paused?
      PausedState.new(true, true, remaining_seconds_after_unpause)
    elsif started?
      RunningState.new(true, false, finish_time)
    else
      NotStartedState.new(false, false, length_minutes)
    end
  end

  def header
    "Remaining in #{@round.stage.format.humanize(capitalize: false)} round #{@round.number}#{paused? ? ' (paused)' : ''}:"
  end

  private

  RunningState = Struct.new(:started, :paused, :finish_time)
  PausedState = Struct.new(:started, :paused, :remaining_seconds)
  NotStartedState = Struct.new(:started, :paused, :length_minutes)
  attr_reader :round
  delegate :round_timer_activations, :completed?, :length_minutes, to: :round

  def finish_time
    last = last_activation
    if !last.nil? && (last.stop_time.nil? || last.stop_time >= expected_end)
      expected_end
    else
      nil
    end
  end

  def expected_end
    unless last_activation.nil?
      last_activation.start_time + length_seconds - prev_activations_seconds
    end
  end

  def remaining_seconds_after_unpause
    seconds = length_seconds - all_activation_seconds
    [0, seconds].max
  end

  def length_seconds
    length_minutes * 60
  end

  def prev_activations_seconds
    round_timer_activations[0..-2].map{|a| a.committed_seconds}.sum
  end

  def all_activation_seconds
    round_timer_activations.map{|a| a.committed_seconds}.sum
  end

  def last_activation
    round_timer_activations.last
  end

end
