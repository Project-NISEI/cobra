# frozen_string_literal: true

RSpec.describe 'destroying players' do
  let(:tournament) { create(:tournament) }
  let!(:player) { create(:player, tournament:) }

  before do
    sign_in tournament.user
    round = create(:round, tournament:)
    create(:pairing, round:, player1: player, player2: nil)

    visit tournament_players_path(tournament)
  end

  it 'deletes player' do
    expect do
      click_link 'Delete'
    end.to change(tournament.players, :count).by(-1)

    expect do
      player.reload
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'redirects to players page' do
    click_link 'Delete'

    expect(page).to have_current_path(tournament_players_path(tournament), ignore_query: true)
  end
end
