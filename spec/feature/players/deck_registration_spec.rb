RSpec.describe 'registering a deck from NetrunnerDB' do
  let(:organiser) { create(:user, nrdb_access_token: 'a_token') }
  let(:player) { create(:user, nrdb_access_token: 'a_token') }
  before do
    sign_in organiser
    visit new_tournament_path
    fill_in 'Tournament name', with: 'Test Tournament'
    check :tournament_self_registration
    check :tournament_nrdb_deck_registration
    click_button 'Create'
  end

  it 'registers as a player' do
    expect do
      register_as_player
    end.to change(Player, :count).by(1)
    expect(page.current_path).to eq(registration_tournament_path(Tournament.last))
  end

  it 'registers TO as a player' do
    expect do
      register_as_organizer
    end.to change(Player, :count).by(1)
    expect(page.current_path).to eq(registration_tournament_path(Tournament.last))
  end

  it 'creates a player as the TO' do
    expect do
      create_player_as_organizer
    end.to change(Player, :count).by(1)
    expect(page.current_path).to eq(tournament_players_path(Tournament.last))
  end

  def register_as_player
    sign_in player
    visit tournament_path(Tournament.last)
    VCR.use_cassette 'nrdb_decks/simplified_deck' do
      click_button 'Register'
    end
  end

  def register_as_organizer
    visit tournament_path(Tournament.last)
    fill_in 'Name', with: 'Test Player'
    VCR.use_cassette 'nrdb_decks/simplified_deck' do
      click_button 'Register'
    end
  end

  def create_player_as_organizer
    visit tournament_players_path(Tournament.last)
    fill_in 'Name', with: 'Test Player'
    click_button 'Create'
  end

end
