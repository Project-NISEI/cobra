# frozen_string_literal: true

class SelfReport < ApplicationRecord
  belongs_to :pairing, touch: true
end
