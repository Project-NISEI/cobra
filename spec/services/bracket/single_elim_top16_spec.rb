# frozen_string_literal: true

RSpec.describe Bracket::SingleElimTop16 do
  let(:tournament) { create(:tournament) }
  let(:stage) { tournament.stages.create(format: :double_elim) }
  let(:bracket) { described_class.new(stage) }

  %w[alpha bravo charlie delta echo foxtrot golf hotel
     india juliet kilo lima mike november oscar papa].each do |name|
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
    create(:registration, player: india, stage:, seed: 9)
    create(:registration, player: juliet, stage:, seed: 10)
    create(:registration, player: kilo, stage:, seed: 11)
    create(:registration, player: lima, stage:, seed: 12)
    create(:registration, player: mike, stage:, seed: 13)
    create(:registration, player: november, stage:, seed: 14)
    create(:registration, player: oscar, stage:, seed: 15)
    create(:registration, player: papa, stage:, seed: 16)
  end

  describe '#bracket' do
    context 'when round 1' do
      let(:pair) { bracket.pair(1) }

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 1, player1: alpha, player2: papa },
                                        { table_number: 2, player1: bravo, player2: oscar },
                                        { table_number: 3, player1: charlie, player2: november },
                                        { table_number: 4, player1: delta, player2: mike },
                                        { table_number: 5, player1: echo, player2: lima },
                                        { table_number: 6, player1: foxtrot, player2: kilo },
                                        { table_number: 7, player1: golf, player2: juliet },
                                        { table_number: 8, player1: hotel, player2: india })
      end

      it 'returns correct standings' do
        expect(bracket.standings.map(&:player)).to eq(
          [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
        )
      end
    end

    context 'when round 2' do
      let(:pair) { bracket.pair(2) }

      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 0, papa, 3
        report r1, 2, bravo, 3, oscar, 0
        report r1, 3, charlie, 0, november, 3
        report r1, 4, delta, 3, mike, 0
        report r1, 5, echo, 0, lima, 3
        report r1, 6, foxtrot, 0, kilo, 3
        report r1, 7, golf, 0, juliet, 3
        report r1, 8, hotel, 0, india, 3
      end

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 9, player1: bravo, player2: papa },
                                        { table_number: 10, player1: delta, player2: november },
                                        { table_number: 11, player1: india, player2: lima },
                                        { table_number: 12, player1: juliet, player2: kilo })
      end

      it 'returns correct standings' do
        expect(bracket.standings.map(&:player)).to eq(
          [nil, nil, nil, nil, nil, nil, nil, nil, alpha, charlie, echo, foxtrot, golf, hotel, mike, oscar]
        )
      end
    end

    context 'when round 3' do
      let(:pair) { bracket.pair(3) }

      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 0, papa, 3
        report r1, 2, bravo, 3, oscar, 0
        report r1, 3, charlie, 0, november, 3
        report r1, 4, delta, 3, mike, 0
        report r1, 5, echo, 0, lima, 3
        report r1, 6, foxtrot, 0, kilo, 3
        report r1, 7, golf, 0, juliet, 3
        report r1, 8, hotel, 0, india, 3

        r2 = create(:round, stage:, completed: true)
        report r2, 9, bravo, 0, papa, 3
        report r2, 10, delta, 3, november, 0
        report r2, 11, india, 0, lima, 3
        report r2, 12, juliet, 3, kilo, 0
      end

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 13, player1: delta, player2: papa },
                                        { table_number: 14, player1: juliet, player2: lima })
      end

      it 'returns correct standings' do
        expect(bracket.standings.map(&:player)).to eq(
          [nil, nil, nil, nil, bravo, india, kilo, november, alpha, charlie, echo, foxtrot, golf, hotel, mike, oscar]
        )
      end
    end

    context 'when round 4' do
      let(:pair) { bracket.pair(4) }

      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 0, papa, 3
        report r1, 2, bravo, 3, oscar, 0
        report r1, 3, charlie, 0, november, 3
        report r1, 4, delta, 3, mike, 0
        report r1, 5, echo, 0, lima, 3
        report r1, 6, foxtrot, 0, kilo, 3
        report r1, 7, golf, 0, juliet, 3
        report r1, 8, hotel, 0, india, 3

        r2 = create(:round, stage:, completed: true)
        report r2, 9, bravo, 0, papa, 3
        report r2, 10, delta, 3, november, 0
        report r2, 11, india, 0, lima, 3
        report r2, 12, juliet, 3, kilo, 0

        r3 = create(:round, stage:, completed: true)
        report r3, 13, delta, 0, papa, 3
        report r3, 14, juliet, 3, lima, 0
      end

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 15, player1: juliet, player2: papa })
      end

      it 'returns correct standings' do
        expect(bracket.standings.map(&:player)).to eq(
          [nil, nil, delta, lima, bravo, india, kilo, november, alpha, charlie, echo, foxtrot, golf, hotel, mike, oscar]
        )
      end
    end

    context 'when bracket is complete' do
      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 0, papa, 3
        report r1, 2, bravo, 3, oscar, 0
        report r1, 3, charlie, 0, november, 3
        report r1, 4, delta, 3, mike, 0
        report r1, 5, echo, 0, lima, 3
        report r1, 6, foxtrot, 0, kilo, 3
        report r1, 7, golf, 0, juliet, 3
        report r1, 8, hotel, 0, india, 3

        r2 = create(:round, stage:, completed: true)
        report r2, 9, bravo, 0, papa, 3
        report r2, 10, delta, 3, november, 0
        report r2, 11, india, 0, lima, 3
        report r2, 12, juliet, 3, kilo, 0

        r3 = create(:round, stage:, completed: true)
        report r3, 13, delta, 0, papa, 3
        report r3, 14, juliet, 3, lima, 0

        r4 = create(:round, stage:, completed: true)
        report r4, 15, juliet, 3, papa, 0
      end

      it 'returns correct standings' do
        expect(bracket.standings.map(&:player)).to eq(
          [juliet, papa, delta, lima, bravo, india, kilo, november, alpha, charlie, echo, foxtrot, golf, hotel, mike,
           oscar]
        )
      end
    end
  end
end
