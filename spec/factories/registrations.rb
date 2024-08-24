# frozen_string_literal: true

FactoryBot.define do
  factory :registration do
    player
    stage
    seed { nil }
  end
end
