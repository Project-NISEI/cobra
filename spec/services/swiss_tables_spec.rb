# frozen_string_literal: true

RSpec.describe SwissTables do
  # thin_players[player_id] = ThinPlayer.new(
  #   player_id, data[:name], data[:active], data[:first_round_bye], data[:points],
  #   data[:opponents], data[:side_bias], data[:fixed_table_number]
  # )

  let(:alice) { ThinPlayer.new(1, 'Alice', true, false, 0, {}, 0, nil) }
  let(:bob) { ThinPlayer.new(2, 'Bob', true, false, 6, {}, 0, nil) }
  let(:charlie) { ThinPlayer.new(3, 'Charlie', true, false, 0, {}, 0, nil) }
  let(:dave) { ThinPlayer.new(4, 'Dave', true, false, 0, {}, 0, nil) }
  let(:eddie) { ThinPlayer.new(5, 'Eddie', true, false, 6, {}, 0, nil) }
  let(:florence) { ThinPlayer.new(6, 'Florence', true, false, 6, {}, 0, nil) }

  let(:alice_bob) { ThinPairing.new(alice, 0, bob, 0) }
  let(:charlie_dave) { ThinPairing.new(charlie, 0, dave, 0) }
  let(:eddie_florence) { ThinPairing.new(eddie, 0, florence, 0) }

  let(:alice_bye) { ThinPairing.new(alice, 0, nil, 0) }
  let(:alice_florence) { ThinPairing.new(alice, 0, florence, 0) }
  let(:bob_charlie) { ThinPairing.new(bob, 0, charlie, 0) }
  let(:dave_eddie) { ThinPairing.new(dave, 0, eddie, 0) }

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
