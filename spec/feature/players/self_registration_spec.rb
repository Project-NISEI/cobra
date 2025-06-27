# frozen_string_literal: true

RSpec.describe 'registering for a tournament' do
  let(:organiser) { create(:user) }
  let(:player) { create(:user) }
  let(:tournament) { create(:tournament, user: organiser, self_registration: true) }

  it 'registers player' do
    expect do
      register_player player
    end.to change(Player, :count).by(1)
    expect(page).to have_current_path(tournament_path(tournament), ignore_query: true)
    expect(Player.last.user_id).to be(player.id)
  end

  it 'registers player when tournament has no stages' do
    delete_tournament_stage

    expect do
      register_player player
    end.to change(Player, :count).by(1)
    expect(page).to have_current_path(tournament_path(tournament), ignore_query: true)
    expect(Player.last.user_id).to be(player.id)
  end

  it 'TO registers themselves as a player' do
    expect do
      register_player organiser
    end.to change(Player, :count).by(1)
    expect(page).to have_current_path(tournament_path(tournament), ignore_query: true)
    expect(Player.last.user_id).to be(organiser.id)
  end

  def register_player(user)
    sign_in user
    visit tournament_path(tournament)
    fill_in :player_corp_identity, with: 'Haas-Bioroid: Engineering the Future'
    fill_in :player_runner_identity, with: 'Noise'
    click_button 'Register'
  end

  def delete_tournament_stage
    sign_in organiser
    visit tournament_rounds_path(tournament)
    click_on class: ['btn-danger']
  end
end
