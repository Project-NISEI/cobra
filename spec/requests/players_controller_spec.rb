RSpec.describe PlayersController do

  describe 'self registration' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:tournament) { create(:tournament, name: 'My Tournament', self_registration: true) }

    describe '#create' do
      it 'prevents self-registration without logging in' do
        sign_in nil
        post tournament_players_path(tournament), params: { player: { name: 'Unauthorized user' } }

        expect(tournament.players).to be_empty
        expect_unauthorized
      end

      it 'prevents self-registration when closed' do
        sign_in user1
        tournament.close_registration!
        post tournament_players_path(tournament), params: { player: { name: 'New player' } }

        expect(tournament.players).to be_empty
        expect_unauthorized
      end

      it 'infers your user ID if you register as yourself' do
        sign_in user1
        post tournament_players_path(tournament), params: { player: { name: 'Player 1' } }

        expect(tournament.players.last.user_id).to be(user1.id)
      end

      it 'infers user ID when TO registers themselves' do
        sign_in tournament.user
        post tournament_players_path(tournament), params: { player: { name: 'Tournament organizer' } }

        expect(tournament.players.last.user_id).to be(tournament.user.id)
      end

      it 'does not set user ID when TO registers another player' do
        sign_in tournament.user
        post tournament_players_path(tournament), params: { player: { name: 'Other player', organiser_view: true } }

        expect(tournament.players.last.user_id).to be_nil
      end
    end

    describe '#update' do
      let(:player1) { create(:player, name: 'Player 1', tournament: tournament, user_id: user1.id) }
      it 'prevents updating a player without logging in' do
        sign_in nil
        put tournament_player_path(tournament, player1), params: { player: { name: 'Changed Name' } }

        player1.reload
        expect(player1.name).to_not eq('Changed Name')
        expect_unauthorized
      end

      it 'stops you updating another user' do
        sign_in user2
        put tournament_player_path(tournament, player1), params: { player: { name: 'Changed Name' } }

        player1.reload
        expect(player1.name).to_not eq('Changed Name')
        expect_unauthorized
      end

      it 'ignores submitting decks when deck registration is not turned on' do
        sign_in user1
        put tournament_player_path(tournament, player1), params: { player: {
          runner_identity: 'Some Runner',
          corp_identity: 'Some Corp',
          runner_deck: '{"details": {"name": "Runner Deck"}, "cards": []}',
          corp_deck: '{"details": {"name": "Corp Deck"}, "cards": []}'
        } }

        player1.reload
        expect(player1.runner_identity).to eq('Some Runner')
        expect(player1.corp_identity).to eq('Some Corp')
        expect(player1.runner_deck).to be_nil
        expect(player1.corp_deck).to be_nil
      end

      it 'refuses player details change when player is locked' do
        sign_in tournament.user
        patch lock_registration_tournament_player_path(tournament, player1)
        sign_in user1
        put tournament_player_path(tournament, player1), params: { player: {
          name: 'Updated name',
          pronouns: 'they/them',
          corp_identity: 'Some corp',
          runner_identity: 'Some runner',
        } }

        player1.reload
        expect(player1.name).to eq('Player 1')
        expect(player1.pronouns).to be_nil
        expect(player1.corp_identity).to be_nil
        expect(player1.runner_identity).to be_nil
        expect_unauthorized
      end

      it 'allows TO updating another user' do
        sign_in tournament.user
        put tournament_player_path(tournament, player1), params: { player: { name: 'Changed Name' } }

        player1.reload
        expect(player1.name).to eq('Changed Name')
      end

      it 'allows TO updating themselves' do
        sign_in tournament.user
        post tournament_players_path(tournament), params: { player: { name: 'Tournament organiser' } }
        put tournament_player_path(tournament, Player.last), params: { player: { name: 'Mr. Organiser' } }

        expect(Player.last.user_id).to be(tournament.user.id)
        expect(Player.last.name).to eq('Mr. Organiser')
      end

      it 'allows TO updating themselves in the organiser view' do
        sign_in tournament.user
        post tournament_players_path(tournament), params: { player: { name: 'Tournament organiser' } }
        put tournament_player_path(tournament, Player.last), params: { player: { name: 'Mr. Organiser', organiser_view: true } }

        expect(Player.last.user_id).to be(tournament.user.id)
        expect(Player.last.name).to eq('Mr. Organiser')
      end
    end
  end

  describe 'deck submission' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }
    let(:tournament) { create(:tournament, self_registration: true, nrdb_deck_registration: true) }

    before do
      sign_in user1
      post tournament_players_path(tournament), params: { player: { name: 'Player 1' } }
      sign_in user2
      post tournament_players_path(tournament), params: { player: { name: 'Player 2' } }
      @player1 = Player.find_by! user_id: user1.id
      @player2 = Player.find_by! user_id: user2.id
    end

    it 'stores decks' do
      sign_in user1
      put tournament_player_path(tournament, @player1), params: { player: {
        corp_deck: '{"details": {"name": "Corp Deck"}, "cards": []}',
        runner_deck: '{"details": {"name": "Runner Deck"}, "cards": []}',
      } }

      @player1.reload
      expect(@player1.corp_deck.name).to eq('Corp Deck')
      expect(@player1.runner_deck.name).to eq('Runner Deck')
    end

    it 'stores cards' do
      sign_in user1
      put tournament_player_path(tournament, @player1), params: { player: {
        corp_deck: '{"details": {}, "cards": [{"title": "Corp Card", "quantity": 3}]}',
        runner_deck: '{"details": {}, "cards": [{"title": "Runner Card", "quantity": 3}]}',
      } }

      @player1.reload
      expect(@player1.corp_deck.cards.map { |card| [card.title, card.quantity] }).to eq([['Corp Card', 3]])
      expect(@player1.runner_deck.cards.map { |card| [card.title, card.quantity] }).to eq([['Runner Card', 3]])
    end

    it 'deletes decks' do
      sign_in user1
      put tournament_player_path(tournament, @player1), params: { player: {
        corp_deck: '{"details": {"name": "Corp Deck"}, "cards": []}',
        runner_deck: '{"details": {"name": "Runner Deck"}, "cards": []}',
      } }
      put tournament_player_path(tournament, @player1), params: { player: {
        corp_deck: '',
        runner_deck: '',
      } }

      @player1.reload
      expect(@player1.corp_deck).to be_nil
      expect(@player1.runner_deck).to be_nil
    end

    it 'ignores decks when player is locked' do
      sign_in tournament.user
      patch lock_registration_tournament_player_path(tournament, @player1)
      sign_in user1
      put tournament_player_path(tournament, @player1), params: { player: {
        corp_deck: '{"details": {"name": "Corp Deck"}, "cards": []}',
        runner_deck: '{"details": {"name": "Runner Deck"}, "cards": []}',
      } }

      @player1.reload
      expect(@player1.corp_deck).to be_nil
      expect(@player1.runner_deck).to be_nil
    end

    it 'has all decks unlocked to begin with' do
      expect(@player1.reload.registration_locked?).to be(false)
      expect(@player2.reload.registration_locked?).to be(false)
      expect(tournament.reload.all_players_unlocked?).to be(true)
      expect(tournament.any_player_unlocked?).to be(true)
    end

    it 'locks decks for the whole tournament when registration closes' do
      sign_in tournament.user
      patch close_registration_tournament_path(tournament)

      expect(@player1.reload.registration_locked?).to be(true)
      expect(@player2.reload.registration_locked?).to be(true)
      expect(tournament.reload.all_players_unlocked?).to be(false)
      expect(tournament.any_player_unlocked?).to be(false)
    end

    it 'locks decks for one player but not the other' do
      sign_in tournament.user
      patch lock_registration_tournament_player_path(tournament, @player1)

      expect(@player1.reload.registration_locked?).to be(true)
      expect(@player2.reload.registration_locked?).to be(false)
      expect(tournament.reload.all_players_unlocked?).to be(false)
      expect(tournament.any_player_unlocked?).to be(true)
    end

    it 'unlocks decks for one player' do
      sign_in tournament.user
      patch close_registration_tournament_path(tournament)
      patch unlock_registration_tournament_player_path(tournament, @player1)

      expect(@player1.reload.registration_locked?).to be(false)
      expect(@player2.reload.registration_locked?).to be(true)
      expect(tournament.reload.all_players_unlocked?).to be(false)
      expect(tournament.any_player_unlocked?).to be(true)
    end

    it 'unlocks decks for all players' do
      sign_in tournament.user
      patch close_registration_tournament_path(tournament)
      patch unlock_player_registrations_tournament_path(tournament)

      expect(@player1.reload.registration_locked?).to be(false)
      expect(@player2.reload.registration_locked?).to be(false)
      expect(tournament.reload.all_players_unlocked?).to be(true)
      expect(tournament.any_player_unlocked?).to be(true)
    end

    it 'does not unlock decks when reopening registration' do
      sign_in tournament.user
      patch close_registration_tournament_path(tournament)
      patch open_registration_tournament_path(tournament)

      expect(@player1.reload.registration_locked?).to be(true)
      expect(@player2.reload.registration_locked?).to be(true)
      expect(tournament.reload.all_players_unlocked?).to be(false)
      expect(tournament.any_player_unlocked?).to be(false)
    end

    it 'locks decks for all players individually' do
      sign_in tournament.user
      patch lock_registration_tournament_player_path(tournament, @player1)
      patch lock_registration_tournament_player_path(tournament, @player2)

      expect(@player1.reload.registration_locked?).to be(true)
      expect(@player2.reload.registration_locked?).to be(true)
      expect(tournament.reload.all_players_unlocked?).to be(false)
      expect(tournament.any_player_unlocked?).to be(false)
    end

    it 'unlocks decks for all players individually' do
      sign_in tournament.user
      patch close_registration_tournament_path(tournament)
      patch unlock_registration_tournament_player_path(tournament, @player1)
      patch unlock_registration_tournament_player_path(tournament, @player2)

      expect(@player1.reload.registration_locked?).to be(false)
      expect(@player2.reload.registration_locked?).to be(false)
      expect(tournament.reload.all_players_unlocked?).to be(true)
      expect(tournament.any_player_unlocked?).to be(true)
    end

    it 'unlocks decks for all but one player' do
      sign_in tournament.user
      patch close_registration_tournament_path(tournament)
      patch unlock_player_registrations_tournament_path(tournament)
      patch lock_registration_tournament_player_path(tournament, @player1)

      expect(@player1.reload.registration_locked?).to be(true)
      expect(@player2.reload.registration_locked?).to be(false)
      expect(tournament.reload.all_players_unlocked?).to be(false)
      expect(tournament.any_player_unlocked?).to be(true)
    end

    it 'does not lock decks for a new player even when all other players are locked' do
      sign_in tournament.user
      patch lock_player_registrations_tournament_path(tournament)
      sign_in user3
      post tournament_players_path(tournament), params: { player: { name: 'Player 3' } }
      @player3 = Player.find_by! user_id: user3.id
      sign_in tournament.user

      expect(@player3.reload.registration_locked?).to be(false)
      expect(tournament.reload.all_players_unlocked?).to be(false)
      expect(tournament.any_player_unlocked?).to be(true)
    end
  end

  def expect_unauthorized
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq("🔒 Sorry, you can't do that")
  end
end
