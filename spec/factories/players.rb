# frozen_string_literal: true

FactoryBot.define do
  factory :player do
    name { Faker::Name.name }
    tournament { Tournament.first || create(:tournament) }
    active { true }
    first_round_bye { false }

    transient do
      skip_registration { false }
      seed { nil }
    end

    after(:create) do |player, evaluator|
      unless evaluator.skip_registration
        create(
          :registration,
          player:,
          stage: player.tournament.current_stage,
          seed: evaluator.seed
        )
      end
    end
  end
end
