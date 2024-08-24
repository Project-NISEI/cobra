# frozen_string_literal: true

class RoundTimerActivation < ApplicationRecord
  belongs_to :round, touch: true
  has_one :tournament, through: :round

  def committed_seconds
    if stop_time.nil?
      0
    else
      stop_time - start_time
    end
  end
end
