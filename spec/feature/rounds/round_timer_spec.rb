RSpec.describe 'round timer' do
  let(:tournament) { create(:tournament) }
  let(:round) { create(:round, stage: tournament.current_stage) }

  before do
    sign_in round.tournament.user
    visit tournament_rounds_path(round.tournament)
  end

  it 'starts the round timer' do
    click_link 'Start round timer'
  end
end
