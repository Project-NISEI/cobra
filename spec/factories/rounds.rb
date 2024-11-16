# frozen_string_literal: true

FactoryBot.define do
  factory :round do
    number { 1 }
    tournament
    stage
    completed { false }
    weight { 1.0 }
  end
end
