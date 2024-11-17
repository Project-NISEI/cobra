# frozen_string_literal: true

RSpec.describe PairingSorters::Ranked do
  let(:player1) { create(:player) }
  let(:player2) { create(:player) }
  let(:player3) { create(:player) }
  let(:player4) { create(:player) }
  let(:player5) { create(:player) }
  let(:player6) { create(:player) }
  let(:pairing1) { create(:pairing, player1:, player2:) }
  let(:pairing2) { create(:pairing, player1: player3, player2: player4) }
  let(:pairing3) { create(:pairing, player1: player5, player2: player6) }
  let(:pairings) { [pairing1, pairing2, pairing3] }

  before do
    allow(player1).to receive(:points).and_return(3)
    allow(player2).to receive(:points).and_return(1)
    allow(player3).to receive(:points).and_return(6)
    allow(player4).to receive(:points).and_return(0)
    allow(player5).to receive(:points).and_return(3)
    allow(player6).to receive(:points).and_return(2)
  end

  it 'sorts pairings by highest-scoring participant' do
    expect(described_class.sort(pairings)).to eq([pairing2, pairing3, pairing1])
  end

  it 'sorts pairings by highest-scoring participant with ThinPlayer' do
    player_summary = {
      player1.id => ThinPlayer.new(player1.id, player1.name, true, false, 3, {}, 0),
      player2.id => ThinPlayer.new(player2.id, player2.name, true, false, 1, {}, 0),
      player3.id => ThinPlayer.new(player3.id, player3.name, true, false, 6, {}, 0),
      player4.id => ThinPlayer.new(player4.id, player4.name, true, false, 0, {}, 0),
      player5.id => ThinPlayer.new(player5.id, player5.name, true, false, 3, {}, 0),
      player6.id => ThinPlayer.new(player6.id, player6.name, true, false, 2, {}, 0)
    }

    expect(described_class.sort(pairings, player_summary)).to eq([pairing2, pairing3, pairing1])
  end

  context 'odd number of players' do
    let(:pairing3) { create(:pairing, player1: player5, player2: nil) }

    it 'sorts correctly' do
      expect(described_class.sort(pairings)).to eq([pairing2, pairing1, pairing3])
    end
  end
end
