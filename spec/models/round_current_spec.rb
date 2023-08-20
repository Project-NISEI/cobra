RSpec.describe 'round.current?' do
  let(:tournament) { create(:tournament, player_count: 4) }

  context 'round is in swiss' do
    let(:round) { create(:round, stage: tournament.current_stage) }

    it 'should find round is current when in last round of swiss' do
      expect(round.current?).to eq(true)
    end

    it 'should find round is not current when no longer in swiss but cut not paired yet' do
      round.tournament.cut_to! :double_elim, 4
      expect(round.current?).to eq(false)
    end
  end

  context 'round is in cut' do
    let(:round) do
      tournament.cut_to! :double_elim, 4
      tournament.pair_new_round!
    end

    it 'should find round is current when in first round' do
      expect(round.current?).to eq(true)
    end

    it 'should find round is not current when no longer first round' do
      round.pairings.each {|n| n.update(score1: 3, score2: 0)}
      round.update(completed: true)
      round.stage.pair_new_round!
      expect(round.current?).to eq(false)
    end
  end
end