# frozen_string_literal: true

FactoryBot.define do
  factory :tournament_type do
    sequence(:name) { |n| "Tournament Type #{n}" }
    sequence(:position) { |n| n }
    nsg_format { false }
    description { "Description for tournament type" }
  end
end