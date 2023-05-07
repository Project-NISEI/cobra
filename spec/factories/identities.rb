FactoryBot.define do
  factory :identity do
    name { 'Mr Runner' }
    side { :runner }
    faction { :shaper }
    sequence(:nrdb_code) { |n| n.to_s.rjust(5, '0') }
    autocomplete { 'Mr Runner' }
  end
end
