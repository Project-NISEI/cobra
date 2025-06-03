# frozen_string_literal: true

FactoryBot.define do
  factory :format do
    sequence(:name) { |n| "Format #{n}" }
    sequence(:position) { |n| n }
  end
end