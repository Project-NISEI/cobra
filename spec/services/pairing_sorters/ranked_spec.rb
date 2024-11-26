# frozen_string_literal: true

RSpec.describe PairingSorters::Ranked do
  let(:player1) { PlainPlayer.new(1, 'Jason', true, false, points: 3) }
  let(:player2) { PlainPlayer.new(2, 'Mike', true, false, points: 1) }
  let(:player3) { PlainPlayer.new(3, 'Amy', true, false, points: 6) }
  let(:player4) { PlainPlayer.new(4, 'Disha', true, false) }
  let(:player5) { PlainPlayer.new(5, 'Sabrina', true, false, points: 3) }
  let(:player6) { PlainPlayer.new(6, 'Danny', true, false, points: 2) }

  let(:pairing1) { PlainPairing.new(player1, 0, player2, 0) }
  let(:pairing2) { PlainPairing.new(player3, 0, player4, 0) }
  let(:pairing3) { PlainPairing.new(player5, 0, player6, 0) }
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

  context 'odd number of players' do
    let(:pairing3) { PlainPairing.new(player5, 0, nil, 0) }

    it 'sorts correctly' do
      expect(described_class.sort(pairings)).to eq([pairing2, pairing1, pairing3])
    end
  end
end
