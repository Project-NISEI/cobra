# frozen_string_literal: true

RSpec.describe SwissImplementation do
  describe '#pair' do
    10.times do |i|
      let("player#{i}") { SwissImplementation::Player.new("player#{i}") }
    end

    let(:players) do
      [player0, player1, player2, player3, player4,
       player5, player6, player7, player8, player9]
    end
    let(:paired) { described_class.pair(players) }

    it 'pairs correctly' do
      expect(paired.length).to eq(5)
      expect(paired.flatten).to match_array(players)
    end

    context 'with some games played' do
      before do
        player1.delta = 3
        player2.delta = 3
        player3.delta = 1
        player4.delta = 1
      end

      let(:players) { [player1, player2, player3, player4] }
      let(:paired) { described_class.pair(players) }

      it 'pairs players on matching score' do
        paired.each do |p|
          expect(p).to contain_exactly(player1, player2) if p.include?(player1)
          expect(p).to contain_exactly(player3, player4) if p.include?(player3)
        end
      end

      it 'should calculate correct edge values' do
        allow(GraphMatching::Graph::WeightedGraph).to receive(:send).and_call_original

        paired

        expect(GraphMatching::Graph::WeightedGraph).to have_received(:send) do |message, *args|
          expect(message).to eq('[]')
          # order may be inconsistent
          expect(args.map(&:last).sort).to eq([-4, -4, -4, -4, 0, 0])
        end
      end
    end

    context 'with some matchups excluded' do
      before do
        player1.exclude = (players - [player0, player1])
        player2.exclude = [player1]
      end

      let(:paired) { described_class.pair(players) }

      it 'excludes those matchups' do
        paired.each do |p|
          expect(p).to contain_exactly(player1, player0) if p.include?(player1)
        end
      end
    end

    context 'with odd number of players' do
      %i[snap crackle pop].each do |name|
        let(name) { SwissImplementation::Player.new }
      end
      let(:players) { [snap, crackle, pop] }

      it 'pairs correctly' do
        expect(paired.length).to eq(2)
        expect(paired.flatten).to match_array(players + [SwissImplementation::Bye])
      end

      it 'prevents players from receiving a second bye' do
        snap.exclude = [SwissImplementation::Bye]
        crackle.exclude = [SwissImplementation::Bye]

        paired.each do |p|
          expect(p).to contain_exactly(pop, SwissImplementation::Bye) if p.include?(pop)
        end
      end

      it 'always give bye to lowest players' do
        snap.delta = 1
        crackle.delta = 0
        pop.delta = 0

        paired.each do |p|
          expect(p).not_to contain_exactly(snap, SwissImplementation::Bye) if p.include?(SwissImplementation::Bye)
        end
      end
    end

    context 'passing in block for custom weights' do
      let(:players) { [player0, player1, player2, player3] }

      it 'pairs players with a high custom weighting' do
        paired = described_class.pair(players) do |p1, p2|
          next 100 if [p1, p2] - [player0, player3] == []

          5
        end

        paired.each do |p|
          expect(p).to contain_exactly(player0, player3) if p.include?(player0)
        end
      end

      it 'avoids players with a low custom weighting' do
        paired = described_class.pair(players) do |p1, p2|
          next -100 if [p1, p2] - [player0, player1] == []
          next -100 if [p1, p2] - [player0, player2] == []

          15
        end

        paired.each do |p|
          expect(p).to contain_exactly(player0, player3) if p.include?(player0)
        end
      end

      it 'does not allow a pairing if nil weight is returned' do
        paired = described_class.pair(players) do |_p1, _p2|
          nil
        end

        expect(paired).to eq([])
      end
    end
  end
end
