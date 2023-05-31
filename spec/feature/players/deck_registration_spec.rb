RSpec.describe 'registering a deck from NetrunnerDB' do
  let(:organiser) { create(:user, nrdb_access_token: 'a_token') }
  let(:player) { create(:user, nrdb_access_token: 'a_token') }
  before do
    Flipper.enable :nrdb_deck_registration
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

  it 'registers a runner and corp' do
    register_as_player
    create(:identity, nrdb_code: '26010', name: 'Az McCaffrey: Mechanical Prodigy')
    create(:identity, nrdb_code: '01054', name: 'Haas-Bioroid: Engineering the Future')
    VCR.use_cassette 'nrdb_decks/az_palantir_and_jammy_hb' do
      visit registration_tournament_path(Tournament.last)
      az_deck = select_runner_deck_by_id('1455189')
      hb_deck = select_corp_deck_by_id('763461')
      click_button 'Submit'
      updated = Player.last
      expect(updated.corp_identity).to eq('Haas-Bioroid: Engineering the Future')
      expect(updated.runner_identity).to eq('Az McCaffrey: Mechanical Prodigy')
      expect(updated.corp_deck).to eq(hb_deck)
      expect(updated.runner_deck).to eq(az_deck)
    end
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

  def select_corp_deck_by_id(id)
    select_deck_by_id('corp', id)
  end

  def select_runner_deck_by_id(id)
    select_deck_by_id('runner', id)
  end

  def select_deck_by_id(side, id)
    deck = first('#nrdb_deck_'+id)['data-deck']
    first("#player_#{side}_deck", visible: false).set(deck)
    identity = first("#player_#{side}_identity")
    identity.native.remove_attribute('readonly')
    identity.set(deck_identity(deck))
    deck
  end

  def deck_identity(deck_str)
    deck = JSON.parse(deck_str)
    nrdb_codes = deck['cards'].keys
    Identity.where(nrdb_code: nrdb_codes).first!.name
  end

  def with_nrdb_decks(&block)
    VCR.use_cassette 'nrdb_decks/simplified_deck' do
      block.call
    end
  end

end
