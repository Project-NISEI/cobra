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

  let(:alice_bye) { create(:pairing, player1: alice) }
  let(:alice_florence) { create(:pairing, player1: alice, player2: florence) }
  let(:bob_charlie) { create(:pairing, player1: bob, player2: charlie) }
  let(:dave_eddie) { create(:pairing, player1: dave, player2: eddie) }

  describe '#assign_table_numbers!' do

    it 'sets numbers for non-bye pairings' do
      pairings = [alice_bob, charlie_dave]

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to contain_exactly(1, 2)
    end

    it 'puts bye pairing at the end' do
      pairings = [alice_bye, bob_charlie]

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to contain_exactly(2, 1)
    end

    it 'sorts by number of points' do
      alice_florence.update(score1: 0, score2: 6)
      bob_charlie.update(score1: 0, score2: 6)
      dave_eddie.update(score1: 0, score2: 6)
      pairings = [alice_bob, charlie_dave, eddie_florence] # 0 points, 6 points, 12 points

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to contain_exactly(3, 2, 1)
    end

    it 'sets fixed table number' do
      charlie.update(fixed_table_number: 5)
      pairings = [alice_bob, charlie_dave, eddie_florence]

      described_class.assign_table_numbers! pairings

      expect(pairings.map(&:table_number)).to contain_exactly(1, 5, 2)
    end
  end

end