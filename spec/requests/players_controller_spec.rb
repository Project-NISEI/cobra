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

      it 'stops you registering as another user' do
        sign_in player1
        post tournament_players_path(tournament), params: { player: { user_id: player2.id } }

        expect(tournament.players.last.user_id).to be(player1.id)
      end

      it 'allows TO registering another user' do
        sign_in tournament.user
        post tournament_players_path(tournament), params: { player: { user_id: player2.id } }

        expect(tournament.players.last.user_id).to be(player2.id)
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

      it 'stops you impersonating another user' do
        sign_in player2
        put tournament_player_path(tournament, player2_registration), params: { player: { user_id: player1.id } }

        player2_registration.reload
        expect(player2_registration.user_id).to be(player2.id)
      end
    end
  end

  def expect_unauthorized
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq("🔒 Sorry, you can't do that")
  end
end
