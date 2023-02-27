RSpec.describe 'registering a deck from NetrunnerDB' do
  let(:organiser) { create(:user) }
  let(:player) { create(:user) }
  before do
    sign_in organiser
    visit new_tournament_path
    fill_in 'Tournament name', with: 'Test Tournament'
    check :tournament_self_registration
    check :tournament_nrdb_deck_registration
    click_button 'Create'
  end

  it 'registers a player' do
    expect do
      register_as_player
    end.to change(Player, :count).by(1)
    expect(page.current_path).to eq(deck_registration_tournament_player_path(Tournament.last, Player.last))
  end

  it 'registers a player as the TO' do
    expect do
      register_as_organizer
    end.to change(Player, :count).by(1)
    expect(page.current_path).to eq(deck_registration_tournament_player_path(Tournament.last, Player.last))
  end

  def register_as_player
    sign_in player
    visit tournament_path(Tournament.last)
    click_button 'Register'
  end

  def register_as_organizer
    visit tournament_path(Tournament.last)
    fill_in 'Name', with: 'Test Player'
    click_button 'Register'
  end

end
