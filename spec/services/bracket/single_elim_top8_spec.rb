# frozen_string_literal: true

RSpec.describe Bracket::SingleElimTop8 do
  let(:tournament) { create(:tournament) }
  let(:stage) { tournament.stages.create(format: :double_elim) }
  let(:bracket) { described_class.new(stage) }

  %w[alpha bravo charlie delta echo foxtrot golf hotel].each do |name|
    let!(name) { create(:player, tournament:, name:) }
  end

  before do
    create(:registration, player: alpha, stage:, seed: 1)
    create(:registration, player: bravo, stage:, seed: 2)
    create(:registration, player: charlie, stage:, seed: 3)
    create(:registration, player: delta, stage:, seed: 4)
    create(:registration, player: echo, stage:, seed: 5)
    create(:registration, player: foxtrot, stage:, seed: 6)
    create(:registration, player: golf, stage:, seed: 7)
    create(:registration, player: hotel, stage:, seed: 8)
  end

  describe '#bracket' do
    context 'when round 1' do
      let(:pair) { bracket.pair(1) }

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 1, player1: alpha, player2: hotel },
                                        { table_number: 2, player1: bravo, player2: golf },
                                        { table_number: 3, player1: charlie, player2: foxtrot },
                                        { table_number: 4, player1: delta, player2: echo })
      end

      it 'returns correct standings' do
        expect(bracket.standings.map(&:player)).to eq(
          [nil, nil, nil, nil, nil, nil, nil, nil]
        )
      end
    end

    context 'when round 2' do
      let(:pair) { bracket.pair(2) }

      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, hotel, 0
        report r1, 2, bravo, 0, golf, 3
        report r1, 3, charlie, 0, foxtrot, 3
        report r1, 4, delta, 3, echo, 0
      end

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 5, player1: alpha, player2: golf },
                                        { table_number: 6, player1: delta, player2: foxtrot })
      end

      it 'returns correct standings' do
        expect(bracket.standings.map(&:player)).to eq(
          [nil, nil, nil, nil, bravo, charlie, echo, hotel]
        )
      end
    end

    context 'when round 3' do
      let(:pair) { bracket.pair(3) }

      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, hotel, 0
        report r1, 2, bravo, 0, golf, 3
        report r1, 3, charlie, 0, foxtrot, 3
        report r1, 4, delta, 3, echo, 0

        r2 = create(:round, stage:, completed: true)
        report r2, 5, alpha, 0, golf, 3
        report r2, 6, delta, 0, foxtrot, 3
      end

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 7, player1: foxtrot, player2: golf })
      end

      it 'returns correct standings' do
        expect(bracket.standings.map(&:player)).to eq(
          [nil, nil, alpha, delta, bravo, charlie, echo, hotel]
        )
      end
    end

    context 'when bracket is complete' do
      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, hotel, 0
        report r1, 2, bravo, 0, golf, 3
        report r1, 3, charlie, 0, foxtrot, 3
        report r1, 4, delta, 3, echo, 0

        r2 = create(:round, stage:, completed: true)
        report r2, 5, alpha, 0, golf, 3
        report r2, 6, delta, 0, foxtrot, 3

        r3 = create(:round, stage:, completed: true)
        report r3, 7, foxtrot, 0, golf, 3
      end

      it 'returns correct standings' do
        expect(bracket.standings.map(&:player)).to eq(
          [golf, foxtrot, alpha, delta, bravo, charlie, echo, hotel]
        )
      end
    end
  end
end
