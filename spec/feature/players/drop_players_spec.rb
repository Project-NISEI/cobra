# frozen_string_literal: true

RSpec.describe 'dropping players' do
  let(:tournament) { create(:tournament) }
  let!(:player) { create(:player, tournament:, active: true) }

  before do
    sign_in tournament.user
    visit tournament_players_path(tournament)
  end

  it 'drops player' do
    expect do
      click_link 'Drop'
    end.not_to change(tournament.players, :count)

    expect(player.reload.active).to be(false)
  end

  it 'redirects to players page' do
    click_link 'Drop'

    expect(page).to have_current_path(tournament_players_path(tournament), ignore_query: true)
  end
end
