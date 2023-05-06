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

  it 'TO registers themselves as a player' do
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

  it 'displays a deck in the list' do
    register_as_player
    create(:identity, nrdb_code: '26010', name: 'Az McCaffrey: Mechanical Prodigy')
    VCR.use_cassette 'nrdb_decks/az_palantir_full_deck' do
      visit registration_tournament_path(Tournament.last)
    end
    expect(displayed_decks_names)
      .to eq(['The Palantir - 1st/Undefeated @ Silver Goblin Store Champs'])
    expect(displayed_decks_identities)
      .to eq(['Az McCaffrey: Mechanical Prodigy'])
  end

  def register_as_player
    sign_in player
    visit tournament_path(Tournament.last)
    with_nrdb_decks do
      click_button 'Register'
    end
  end

  def register_as_organizer
    visit tournament_path(Tournament.last)
    fill_in 'Name', with: 'Test Player'
    with_nrdb_decks do
      click_button 'Register'
    end
  end

  def create_player_as_organizer
    visit tournament_players_path(Tournament.last)
    fill_in 'Name', with: 'Test Player'
    click_button 'Create'
  end

  def displayed_decks_names
    find('#nrdb_decks').all('li').map {|deck| deck.find('p').text}
  end

  def displayed_decks_identities
    find('#nrdb_decks').all('li').map {|deck| deck.find('small').text}
  end

  def with_nrdb_decks(&block)
    VCR.use_cassette 'nrdb_decks/simplified_deck' do
      block.call
    end
  end

end
