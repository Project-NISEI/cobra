RSpec.describe PlayersController do

  describe 'self registration' do
    let(:player1) { create(:user) }
    let(:player2) { create(:user) }
    let(:tournament) { create(:tournament, name: 'My Tournament', self_registration: true) }

    it 'prevents self-registration without logging in' do
      sign_in nil
      post tournament_players_path(tournament), params: { player: { name: 'Unauthorized user' } }

      expect(tournament.players).to be_empty
      expect(response.status).to be(403)
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
end
