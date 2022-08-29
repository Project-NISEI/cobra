RSpec.describe 'round timer' do
  let(:tournament) { create(:tournament) }
  let(:round) { create(:round, stage: tournament.current_stage) }

  context 'viewing tournament rounds as the tournament creator' do
    before do
      sign_in round.tournament.user
      visit tournament_rounds_path(round.tournament)
    end

    it 'shows the round timer when started' do
      click_on 'Start round timer'
      expect(page).to have_content('Remaining in round 1')
    end

    it 'does not show the round timer if not started' do
      expect(page).to_not have_content('Remaining in round 1')
    end
  end

  it 'has a default round length' do
    expect(round.length_minutes).to be(65)
  end
end
