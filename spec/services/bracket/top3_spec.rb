RSpec.describe Bracket::Top3 do
    let(:tournament) { create(:tournament) }
    let(:stage) { tournament.stages.create(format: :double_elim) }
    let(:bracket) { described_class.new(stage) }
    %w(alpha bravo charlie delta).each do |name|
      let!(name) { create(:player, tournament: tournament, name: name) }
    end
  
    before do
      create(:registration, player: alpha, stage: stage, seed: 1)
      create(:registration, player: bravo, stage: stage, seed: 2)
      create(:registration, player: charlie, stage: stage, seed: 3)
      create(:registration, player: delta, stage: stage, seed: 4)
    end
  
    describe '#pair' do
      context 'round 1' do
        let(:pair) { bracket.pair(1) }
  
        it 'returns correct pairings' do
          expect(pair).to match_array([
            { table_number: 1, player1: bravo, player2: charlie },
          ])
        end
      end
  
      context 'round 2' do
        let(:pair) { bracket.pair(2) }
  
        before do
          r1 = create(:round, stage: stage, completed: true)
          report r1, 1, bravo, 3, charlie, 0
        end
  
        it 'returns correct pairings' do
          expect(pair).to match_array([
            { table_number: 2, player1: alpha, player2: bravo },
          ])
        end
      end
    end
  
    describe '#standings' do
      context 'complete bracket' do
        before do
          r1 = create(:round, stage: stage, completed: true)
          report r1, 1, bravo, 3, charlie, 0
  
          r2 = create(:round, stage: stage, completed: true)
          report r2, 2, alpha, 3, bravo, 0
        end
  
        it 'returns correct standings' do
          expect(bracket.standings.map(&:player)).to eq(
            [alpha, bravo, charlie]
          )
        end
      end
  
      context 'finals still to play' do
        before do
          r1 = create(:round, stage: stage, completed: true)
          report r1, 1, bravo, 3, charlie, 0
  
        end
  
        it 'returns fixed finishes' do
          expect(bracket.standings.map(&:player)).to eq(
            [nil, nil, charlie]
          )
        end
      end
    end
  end
