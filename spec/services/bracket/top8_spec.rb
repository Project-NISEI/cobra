# frozen_string_literal: true

RSpec.describe Bracket::Top8 do
  let(:tournament) { create(:tournament) }
  let(:stage) { tournament.stages.create(format: :double_elim) }
  let(:bracket) { described_class.new(stage) }

  %w[alpha bravo charlie delta echo foxtrot golf hotel].each_with_index do |name, i|
    let!(name) { create(:player, tournament:, name:, seed: i + 1) }
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

  describe '#pair' do
    context 'when round 1' do
      let(:pair) { bracket.pair(1) }

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 1, player1: alpha, player2: hotel },
                                        { table_number: 2, player1: delta, player2: echo },
                                        { table_number: 3, player1: bravo, player2: golf },
                                        { table_number: 4, player1: charlie, player2: foxtrot })
      end
    end

    context 'when round 2' do
      let(:pair) { bracket.pair(2) }

      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, hotel, 0
        report r1, 2, delta, 3, echo, 0
        report r1, 3, bravo, 3, golf, 0
        report r1, 4, charlie, 3, foxtrot, 0
      end

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 5, player1: alpha, player2: delta },
                                        { table_number: 6, player1: bravo, player2: charlie },
                                        { table_number: 7, player1: hotel, player2: echo },
                                        { table_number: 8, player1: golf, player2: foxtrot })
      end
    end

    context 'when round 3' do
      let(:pair) { bracket.pair(3) }

      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, hotel, 0
        report r1, 2, delta, 3, echo, 0
        report r1, 3, bravo, 3, golf, 0
        report r1, 4, charlie, 3, foxtrot, 0

        r2 = create(:round, stage:, completed: true)
        report r2, 5, alpha, 3, delta, 0
        report r2, 6, bravo, 3, charlie, 0
        report r2, 7, hotel, 0, echo, 3
        report r2, 8, golf, 0, foxtrot, 3
      end

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 9, player1: alpha, player2: bravo },
                                        { table_number: 10, player1: charlie, player2: echo },
                                        { table_number: 11, player1: foxtrot, player2: delta })
      end
    end

    context 'when round 4' do
      let(:pair) { bracket.pair(4) }

      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, hotel, 0
        report r1, 2, delta, 3, echo, 0
        report r1, 3, bravo, 3, golf, 0
        report r1, 4, charlie, 3, foxtrot, 0

        r2 = create(:round, stage:, completed: true)
        report r2, 5, alpha, 3, delta, 0
        report r2, 6, bravo, 3, charlie, 0
        report r2, 7, hotel, 0, echo, 3
        report r2, 8, golf, 0, foxtrot, 3

        r3 = create(:round, stage:, completed: true)
        report r3, 9, alpha, 3, bravo, 0
        report r3, 10, charlie, 3, echo, 0
        report r3, 11, foxtrot, 0, delta, 3
      end

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 12, player1: charlie, player2: delta })
      end
    end

    context 'when round 5' do
      let(:pair) { bracket.pair(5) }

      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, hotel, 0
        report r1, 2, delta, 3, echo, 0
        report r1, 3, bravo, 3, golf, 0
        report r1, 4, charlie, 3, foxtrot, 0

        r2 = create(:round, stage:, completed: true)
        report r2, 5, alpha, 3, delta, 0
        report r2, 6, bravo, 3, charlie, 0
        report r2, 7, hotel, 0, echo, 3
        report r2, 8, golf, 0, foxtrot, 3

        r3 = create(:round, stage:, completed: true)
        report r3, 9, alpha, 3, bravo, 0
        report r3, 10, charlie, 3, echo, 0
        report r3, 11, foxtrot, 0, delta, 3

        report r3, 12, charlie, 3, delta, 0
      end

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 13, player1: bravo, player2: charlie })
      end
    end

    context 'when round 6' do
      let(:pair) { bracket.pair(6) }

      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, hotel, 0
        report r1, 2, delta, 3, echo, 0
        report r1, 3, bravo, 3, golf, 0
        report r1, 4, charlie, 3, foxtrot, 0

        r2 = create(:round, stage:, completed: true)
        report r2, 5, alpha, 3, delta, 0
        report r2, 6, bravo, 3, charlie, 0
        report r2, 7, hotel, 0, echo, 3
        report r2, 8, golf, 0, foxtrot, 3

        r3 = create(:round, stage:, completed: true)
        report r3, 9, alpha, 3, bravo, 0
        report r3, 10, charlie, 3, echo, 0
        report r3, 11, foxtrot, 0, delta, 3

        report r3, 12, charlie, 3, delta, 0
        report r3, 13, bravo, 3, charlie, 0
      end

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 14, player1: alpha, player2: bravo })
      end
    end

    context 'when round 7' do
      let(:pair) { bracket.pair(7) }

      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, hotel, 0
        report r1, 2, delta, 3, echo, 0
        report r1, 3, bravo, 3, golf, 0
        report r1, 4, charlie, 3, foxtrot, 0

        r2 = create(:round, stage:, completed: true)
        report r2, 5, alpha, 3, delta, 0
        report r2, 6, bravo, 3, charlie, 0
        report r2, 7, hotel, 0, echo, 3
        report r2, 8, golf, 0, foxtrot, 3

        r3 = create(:round, stage:, completed: true)
        report r3, 9, alpha, 3, bravo, 0
        report r3, 10, charlie, 3, echo, 0
        report r3, 11, foxtrot, 0, delta, 3

        report r3, 12, charlie, 3, delta, 0
        report r3, 13, bravo, 3, charlie, 0
        report r3, 14, alpha, 0, bravo, 3
      end

      it 'returns correct pairings' do
        expect(pair).to contain_exactly({ table_number: 15, player1: bravo, player2: alpha })
      end
    end
  end

  describe '#standings' do
    context 'when complete bracket' do
      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, hotel, 0
        report r1, 2, delta, 3, echo, 0
        report r1, 3, bravo, 3, golf, 0
        report r1, 4, charlie, 3, foxtrot, 0

        r2 = create(:round, stage:, completed: true)
        report r2, 5, alpha, 3, delta, 0
        report r2, 6, bravo, 3, charlie, 0
        report r2, 7, hotel, 0, echo, 3
        report r2, 8, golf, 0, foxtrot, 3

        r3 = create(:round, stage:, completed: true)
        report r3, 9, alpha, 3, bravo, 0
        report r3, 10, charlie, 3, echo, 0
        report r3, 11, foxtrot, 0, delta, 3

        report r3, 12, charlie, 3, delta, 0
        report r3, 13, bravo, 3, charlie, 0
        report r3, 14, alpha, 0, bravo, 3
        report r3, 15, bravo, 3, alpha, 0
      end

      it 'returns correct standings' do
        expect(bracket.standings.map(&:player)).to eq(
          [bravo, alpha, charlie, delta, echo, foxtrot, golf, hotel]
        )
      end
    end

    context 'when second final still to play' do
      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, hotel, 0
        report r1, 2, delta, 3, echo, 0
        report r1, 3, bravo, 3, golf, 0
        report r1, 4, charlie, 3, foxtrot, 0

        r2 = create(:round, stage:, completed: true)
        report r2, 5, alpha, 3, delta, 0
        report r2, 6, bravo, 3, charlie, 0
        report r2, 7, hotel, 0, echo, 3
        report r2, 8, golf, 0, foxtrot, 3

        r3 = create(:round, stage:, completed: true)
        report r3, 9, alpha, 3, bravo, 0
        report r3, 10, charlie, 3, echo, 0
        report r3, 11, foxtrot, 0, delta, 3

        report r3, 12, charlie, 3, delta, 0
        report r3, 13, bravo, 3, charlie, 0
      end

      let(:r4) { create(:round, stage:, completed: true) }

      context 'when second final required' do
        before do
          report r4, 14, alpha, 0, bravo, 3
        end

        it 'returns ambiguous top two' do
          expect(bracket.standings.map(&:player)).to eq(
            [nil, nil, charlie, delta, echo, foxtrot, golf, hotel]
          )
        end
      end

      context 'when second final not required' do
        before do
          report r4, 14, alpha, 3, bravo, 0
        end

        it 'returns top two' do
          expect(bracket.standings.map(&:player)).to eq(
            [alpha, bravo, charlie, delta, echo, foxtrot, golf, hotel]
          )
        end
      end
    end

    context 'when multiple rounds still to play' do
      before do
        r1 = create(:round, stage:, completed: true)
        report r1, 1, alpha, 3, hotel, 0
        report r1, 2, delta, 3, echo, 0
        report r1, 3, bravo, 3, golf, 0
        report r1, 4, charlie, 3, foxtrot, 0

        r2 = create(:round, stage:, completed: true)
        report r2, 5, alpha, 3, delta, 0
        report r2, 6, bravo, 3, charlie, 0
        report r2, 7, hotel, 0, echo, 3
        report r2, 8, golf, 0, foxtrot, 3

        r3 = create(:round, stage:, completed: true)
        report r3, 9, alpha, 3, bravo, 0
        report r3, 10, charlie, 3, echo, 0
        report r3, 11, foxtrot, 0, delta, 3
      end

      it 'returns fixed finishes' do
        expect(bracket.standings.map(&:player)).to eq(
          [nil, nil, nil, nil, echo, foxtrot, golf, hotel]
        )
      end
    end
  end
end
