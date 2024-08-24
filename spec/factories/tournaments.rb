# frozen_string_literal: true

FactoryBot.define do
  factory :tournament do
    name { 'Tournament Name' }
    user

    transient do
      player_count { 0 }
    end

    after(:create) do |tournament, evaluator|
      create_list(:player, evaluator.player_count, tournament:)
    end
  end
end
