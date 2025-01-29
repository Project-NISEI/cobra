# frozen_string_literal: true

RSpec.describe Bracket::SingleElimTop4 do
  let(:tournament) { create(:tournament) }
  let(:stage) { tournament.stages.create(format: :double_elim) }
  let(:bracket) { described_class.new(stage) }

  %w[alpha bravo charlie delta].each do |name|
    let!(name) { create(:player, tournament:, name:) }
  end

  before do
    create(:registration, player: alpha, stage:, seed: 1)
    create(:registration, player: bravo, stage:, seed: 2)
    create(:registration, player: charlie, stage:, seed: 3)
    create(:registration, player: delta, stage:, seed: 4)
  end

  describe '#bracket' do
    context 'when round 1' do
      let(:pair) { bracket.pair(1) }

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 1, player1: alpha, player2: delta },
                                        { table_number: 2, player1: bravo, player2: charlie })
      end

      it 'returns correct standings' do
        expect(bracket.standings.map(&:player)).to eq(
          [nil, nil, nil, nil]
        )
      end
    end

    context 'when round 2' do
      let(:pair) { bracket.pair(2) }

      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, delta, 0
        report r1, 2, bravo, 3, charlie, 0
      end

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 3, player1: alpha, player2: bravo })
      end

      it 'returns correct standings' do
        expect(bracket.standings.map(&:player)).to eq(
          [nil, nil, charlie, delta]
        )
      end
    end

    context 'when bracket is compelte' do
      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, delta, 0
        report r1, 2, bravo, 3, charlie, 0

        r2 = create(:round, stage:, completed: true)
        report r2, 3, alpha, 0, bravo, 3
      end

      it 'returns correct standings' do
        expect(bracket.standings.map(&:player)).to eq(
          [bravo, alpha, charlie, delta]
        )
      end
    end
  end
end
