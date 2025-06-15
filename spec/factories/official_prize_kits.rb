# frozen_string_literal: true

FactoryBot.define do
  factory :official_prize_kit do
    sequence(:name) { |n| "Official Prize Kit #{n}" }
    sequence(:position) { |n| n }
    link { 'https://example.com/prize-kit' }
    description { 'A great prize kit for tournaments' }
  end
end
