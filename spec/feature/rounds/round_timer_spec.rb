RSpec.describe 'round timer' do
  let(:tournament) { create(:tournament) }
  let(:round) { create(:round, stage: tournament.current_stage) }

  before do
    sign_in round.tournament.user
    visit tournament_round_path(round.tournament, round)
  end

  it 'starts the round timer' do
    # TODO
  end
end
