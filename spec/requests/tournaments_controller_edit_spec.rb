# frozen_string_literal: true

RSpec.describe TournamentsController, type: :request do
  describe '#edit' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:tournament_params) do
      {
        tournament: {
          name: 'Test Tournament',
          stream_url: 'https://twitch.tv/test',
          manual_seed: true,
          self_registration: true,
          date: '2023-05-15'
        }
      }
    end
    let(:tournament) do
      sign_in user
      post tournaments_path, params: tournament_params, as: :json
      post logout_path
      Tournament.last
    end

    before do
      tournament
    end

    context 'when user is signed in as tournament owner' do
      before do
        sign_in user
      end

      it 'returns tournament data' do
        get edit_tournament_path(tournament), as: :json

        expect(response).to be_successful
        expect(response.content_type).to include('application/json')

        expect(JSON.parse(response.body)).to eq(
          {
            'tournament' => {
              'id' => tournament.id,
              'name' => 'Test Tournament',
              'date' => '2023-05-15',
              'stream_url' => 'https://twitch.tv/test',
              'private' => false,
              'manual_seed' => true,
              'self_registration' => true,
              'swiss_format' => 'double_sided',
            },
            'options' => {
              'tournament_types' => [],
              'formats' => [],
              'card_sets' => [],
              'deckbuilding_restrictions' => []
            }
          }
        )
      end

      it 'includes form options data' do
        # Create some reference data
        tournament_type = create(:tournament_type, name: 'Store Championship')
        format = create(:format, name: 'Standard')
        card_set = create(:card_set, name: 'System Gateway')
        restriction = create(:deckbuilding_restriction, name: 'Standard Ban List')

        get edit_tournament_path(tournament), as: :json

        expect(JSON.parse(response.body)).to eq(
          {
            'tournament' => {
              'id' => tournament.id,
              'name' => 'Test Tournament',
              'date' => '2023-05-15',
              'stream_url' => 'https://twitch.tv/test',
              'private' => false,
              'manual_seed' => true,
              'self_registration' => true,
              'swiss_format' => 'double_sided'
            },
            'options' => {
              'tournament_types' => [
                { 'id' => tournament_type.id, 'name' => 'Store Championship' }
              ],
              'formats' => [
                { 'id' => format.id, 'name' => 'Standard' }
              ],
              'card_sets' => [
                { 'id' => card_set.id, 'name' => 'System Gateway' }
              ],
              'deckbuilding_restrictions' => [
                { 'id' => restriction.id, 'name' => 'Standard Ban List' }
              ]
            }
          }
        )
      end
    end

    context 'when user is signed in but not the tournament owner' do
      before do
        sign_in other_user
      end

      it 'returns unauthorized status' do
        get edit_tournament_path(tournament), as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is not signed in' do
      before do
        sign_out
      end

      it 'returns unauthorized status' do
        get edit_tournament_path(tournament), as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
