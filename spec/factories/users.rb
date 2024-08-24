# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    nrdb_id { 1 }
    nrdb_username { 'test_user' }
  end
end
