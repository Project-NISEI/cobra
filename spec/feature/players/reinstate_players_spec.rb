# frozen_string_literal: true

RSpec.describe 'reinstating players' do
  let(:tournament) { create(:tournament) }
  let!(:player) { create(:player, tournament:, active: false) }

  before do
    sign_in tournament.user
    visit tournament_players_path(tournament)
  end

  it 'drops player' do
    expect do
      click_link 'Reinstate'
    end.not_to change(tournament.players, :count)

    expect(player.reload.active).to be(true)
  end

  it 'redirects to players page' do
    click_link 'Reinstate'

    expect(page).to have_current_path(tournament_players_path(tournament), ignore_query: true)
  end
end
