RSpec.describe PlayersController do

  describe 'self registration' do
    let(:player1) { create(:user) }
    let(:player2) { create(:user) }
    let(:tournament) { create(:tournament, name: 'My Tournament', self_registration: true) }

    describe '#create' do
      it 'prevents self-registration without logging in' do
        sign_in nil
        post tournament_players_path(tournament), params: { player: { name: 'Unauthorized user' } }

        expect(tournament.players).to be_empty
        expect_unauthorized
      end

      it 'infers your user ID if you register as yourself' do
        sign_in player1
        post tournament_players_path(tournament), params: { player: { name: 'Player 1' } }

        expect(tournament.players.last.user_id).to be(player1.id)
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
      let(:player2_registration) { create(:player, tournament: tournament, user_id: player2.id) }
      it 'prevents updating a player without logging in' do
        sign_in nil
        put tournament_player_path(tournament, player2_registration), params: { player: { name: 'Changed Name' } }

        player2_registration.reload
        expect(player2_registration.name).to_not eq('Changed Name')
        expect_unauthorized
      end

      it 'stops you updating another user' do
        sign_in player1
        put tournament_player_path(tournament, player2_registration), params: { player: { name: 'Changed Name' } }

        player2_registration.reload
        expect(player2_registration.name).to_not eq('Changed Name')
        expect_unauthorized
      end

      it 'allows TO updating another user' do
        sign_in tournament.user
        put tournament_player_path(tournament, player2_registration), params: { player: { name: 'Changed Name' } }

        player2_registration.reload
        expect(player2_registration.name).to eq('Changed Name')
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
