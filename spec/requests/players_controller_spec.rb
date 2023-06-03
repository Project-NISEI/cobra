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
      let(:player1) { create(:player, tournament: tournament, user_id: user1.id) }
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
          runner_deck: '{"name": "Runner Deck"}',
          corp_deck: '{"name": "Corp Deck"}',
          runner_deck_format: 'nrdb_v2',
          corp_deck_format: 'nrdb_v2'
        } }

        player1.reload
        expect(player1.runner_identity).to eq('Some Runner')
        expect(player1.corp_identity).to eq('Some Corp')
        expect(player1.runner_deck).to be_nil
        expect(player1.corp_deck).to be_nil
        expect(player1.runner_deck_format).to be_nil
        expect(player1.corp_deck_format).to be_nil
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

  def expect_unauthorized
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq("🔒 Sorry, you can't do that")
  end
end
