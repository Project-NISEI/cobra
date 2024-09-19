# frozen_string_literal: true

RSpec.describe SwissTables do
  let(:alice) { create(:player, name: 'Alice') }
  let(:bob) { create(:player, name: 'Bob') }
  let(:charlie) { create(:player, name: 'Charlie') }
  let(:dave) { create(:player, name: 'Dave') }
  let(:eddie) { create(:player, name: 'Eddie') }
  let(:florence) { create(:player, name: 'Florence') }

  let(:alice_bob) { create(:pairing, player1: alice, player2: bob) }
  let(:charlie_dave) { create(:pairing, player1: charlie, player2: dave) }
  let(:eddie_florence) { create(:pairing, player1: eddie, player2: florence) }

  let(:alice_bye) { create(:pairing, player1: alice, player2: nil) }
  let(:alice_florence) { create(:pairing, player1: alice, player2: florence) }
  let(:bob_charlie) { create(:pairing, player1: bob, player2: charlie) }
  let(:dave_eddie) { create(:pairing, player1: dave, player2: eddie) }

  describe '#assign_table_numbers!' do
    it 'sorts non-bye pairings by number of points' do
      alice_florence.update(score1: 0, score2: 6)
      bob_charlie.update(score1: 6, score2: 0)
      dave_eddie.update(score1: 0, score2: 6)
      pairings = [alice_bob, charlie_dave, eddie_florence].freeze # 6 points, 0 points, 12 points

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [2, 3, 1]
    end

    it 'puts bye pairing at the end' do
      alice_bob.update(score1: 6, score2: 0)
      pairings = [alice_bye, bob_charlie].freeze

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [2, 1]
    end

    it 'sets fixed table number' do
      charlie.update(fixed_table_number: 5)
      alice_florence.update(score1: 6, score2: 0)
      bob_charlie.update(score1: 6, score2: 0)
      dave_eddie.update(score1: 6, score2: 0)
      pairings = [alice_bob, charlie_dave, eddie_florence].freeze # 12 points, 6 points, 0 points

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [1, 5, 2]
    end

    it 'chooses lowest fixed table number for a pairing' do
      alice.update(fixed_table_number: 6)
      bob.update(fixed_table_number: 5)
      alice_florence.update(score1: 6, score2: 0)
      bob_charlie.update(score1: 6, score2: 0)
      dave_eddie.update(score1: 6, score2: 0)
      pairings = [alice_bob, charlie_dave, eddie_florence].freeze # 12 points, 6 points, 0 points

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [5, 1, 2]
    end

    it 'excludes fixed table numbers when assigning other tables' do
      alice.update(fixed_table_number: 2)
      alice_florence.update(score1: 6, score2: 0)
      bob_charlie.update(score1: 6, score2: 0)
      dave_eddie.update(score1: 6, score2: 0)
      pairings = [alice_bob, charlie_dave, eddie_florence].freeze # 12 points, 6 points, 0 points

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [2, 1, 3]
    end

    it 'puts bye after non-byes when followed by fixed tables' do
      bob.update(fixed_table_number: 10)
      alice_bob.update(score1: 6, score2: 0)
      charlie_dave.update(score1: 3, score2: 3)
      pairings = [alice_bye, bob_charlie, dave_eddie].freeze

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [2, 10, 1]
    end

    it 'puts bye after non-byes when mixed with fixed tables' do
      bob.update(fixed_table_number: 2)
      alice_bob.update(score1: 6, score2: 0)
      charlie_dave.update(score1: 3, score2: 3)
      pairings = [alice_bye, bob_charlie, dave_eddie].freeze

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to eq [3, 2, 1]
    end
  end
end
