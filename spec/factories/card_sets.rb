# frozen_string_literal: true

FactoryBot.define do
  factory :card_set do
    sequence(:id) { |n| "card-set-#{n}" }
    sequence(:name) { |n| "Card Set #{n}" }
    date_release { Date.today - 30.days }
  end
end