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
  end

  context 'submitting decks' do
    before do
      register_as_player
      create(:identity, nrdb_code: '26010', name: 'Az McCaffrey: Mechanical Prodigy')
      create(:identity, nrdb_code: '01054', name: 'Haas-Bioroid: Engineering the Future')
      VCR.use_cassette 'nrdb_decks/az_palantir_and_jammy_hb' do
        visit registration_tournament_path(Tournament.last)
        select_runner_deck Deck.new identity: 'Az McCaffrey: Mechanical Prodigy'
        select_corp_deck Deck.new identity: 'Haas-Bioroid: Engineering the Future'
        click_button 'Submit'
      end
      @new_player = Player.last
    end

    it 'saves the decks' do
      expect(@new_player.corp_identity).to eq('Haas-Bioroid: Engineering the Future')
      expect(@new_player.runner_identity).to eq('Az McCaffrey: Mechanical Prodigy')
      expect(@new_player.corp_deck.identity).to eq('Haas-Bioroid: Engineering the Future')
      expect(@new_player.runner_deck.identity).to eq('Az McCaffrey: Mechanical Prodigy')
    end

    it 'locks the decks' do
      expect(@new_player.decks_locked).to be(true)
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

  def select_corp_deck(deck)
    select_deck('corp', deck)
  end

  def select_runner_deck(deck)
    select_deck('runner', deck)
  end

  def select_deck(side, deck)
    first("#player_#{side}_deck", visible: false).set({details: deck, cards: []}.to_json)
    identity = first("#player_#{side}_identity")
    identity.native.remove_attribute('readonly')
    identity.set(deck.identity)
  end

  def with_nrdb_decks(&block)
    VCR.use_cassette 'nrdb_decks/simplified_deck' do
      block.call
    end
  end

end
