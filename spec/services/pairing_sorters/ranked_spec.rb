# frozen_string_literal: true

RSpec.describe PairingSorters::Ranked do
  let(:player1) { ThinPlayer.new(1, 'Jason', true, false, 3, {}, 0, false) }
  let(:player2) { ThinPlayer.new(2, 'Mike', true, false, 1, {}, 0, false) }
  let(:player3) { ThinPlayer.new(3, 'Amy', true, false, 6, {}, 0, false) }
  let(:player4) { ThinPlayer.new(4, 'Disha', true, false, 0, {}, 0, false) }
  let(:player5) { ThinPlayer.new(5, 'Sabrina', true, false, 3, {}, 0, false) }
  let(:player6) { ThinPlayer.new(6, 'Danny', true, false, 2, {}, 0, false) }

  let(:pairing1) { ThinPairing.new(player1, 0, player2, 0) }
  let(:pairing2) { ThinPairing.new(player3, 0, player4, 0) }
  let(:pairing3) { ThinPairing.new(player5, 0, player6, 0) }
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
    let(:pairing3) { ThinPairing.new(player5, 0, nil, 0) }

    it 'sorts correctly' do
      expect(described_class.sort(pairings)).to eq([pairing2, pairing1, pairing3])
    end
  end
end
