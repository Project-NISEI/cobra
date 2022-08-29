class RoundTimerActivation < ApplicationRecord
  belongs_to :round, touch: true
  has_one :tournament, through: :round
end
