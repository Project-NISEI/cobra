# frozen_string_literal: true

RSpec.describe SwissTables do
  let(:alice) { PairingStrategies::PlainPlayer.new(1, 'Alice', true, false) }
  let(:bob) { PairingStrategies::PlainPlayer.new(2, 'Bob', true, false, points: 6) }
  let(:charlie) { PairingStrategies::PlainPlayer.new(3, 'Charlie', true, false) }
  let(:dave) { PairingStrategies::PlainPlayer.new(4, 'Dave', true, false) }
  let(:eddie) { PairingStrategies::PlainPlayer.new(5, 'Eddie', true, false, points: 6) }
  let(:florence) { PairingStrategies::PlainPlayer.new(6, 'Florence', true, false, points: 6) }

  let(:alice_bob) { PairingStrategies::PlainPairing.new(alice, 0, bob, 0) }
  let(:charlie_dave) { PairingStrategies::PlainPairing.new(charlie, 0, dave, 0) }
  let(:eddie_florence) { PairingStrategies::PlainPairing.new(eddie, 0, florence, 0) }

  let(:alice_bye) { PairingStrategies::PlainPairing.new(alice, 0, nil, 0) }
  let(:alice_florence) { PairingStrategies::PlainPairing.new(alice, 0, florence, 0) }
  let(:bob_charlie) { PairingStrategies::PlainPairing.new(bob, 0, charlie, 0) }
  let(:dave_eddie) { PairingStrategies::PlainPairing.new(dave, 0, eddie, 0) }

  describe '#assign_table_numbers!' do
    it 'sorts non-bye pairings by number of points' do
      pairings = [alice_bob, charlie_dave, eddie_florence].freeze # 6 points, 0 points, 12 points

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [2, 3, 1]
    end

    it 'puts bye pairing at the end' do
      alice.points = 6
      pairings = [alice_bye, bob_charlie].freeze

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [2, 1]
    end

    it 'sets fixed table number' do
      charlie.fixed_table_number = 5
      alice.points = 6
      bob.points = 6
      dave.points = 6
      pairings = [alice_bob, charlie_dave, eddie_florence].freeze # 12 points, 6 points, 0 points

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [1, 5, 2]
    end

    it 'chooses lowest fixed table number for a pairing' do
      alice.fixed_table_number = 6
      bob.fixed_table_number = 5
      alice.points = 6
      bob.points = 6
      dave.points = 6
      eddie.points = 0
      florence.points = 0

      pairings = [alice_bob, charlie_dave, eddie_florence].freeze # 12 points, 6 points, 0 points

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [5, 1, 2]
    end

    it 'excludes fixed table numbers when assigning other tables' do
      alice.fixed_table_number = 2
      alice.points = 6
      florence.points = 0
      bob.points = 6
      charlie.points = 0
      dave.points = 6
      eddie.points = 0
      pairings = [alice_bob, charlie_dave, eddie_florence].freeze # 12 points, 6 points, 0 points

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [2, 1, 3]
    end

    it 'puts bye after non-byes when followed by fixed tables' do
      bob.fixed_table_number = 10
      alice.points = 6
      bob.points = 0
      charlie.points = 3
      dave.points = 3
      pairings = [alice_bye, bob_charlie, dave_eddie].freeze

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [2, 10, 1]
    end

    it 'puts bye after non-byes when mixed with fixed tables' do
      bob.fixed_table_number = 2
      alice.points = 6
      bob.points = 0
      charlie.points = 3
      dave.points = 3
      pairings = [alice_bye, bob_charlie, dave_eddie].freeze

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [3, 2, 1]
    end
  end
end
