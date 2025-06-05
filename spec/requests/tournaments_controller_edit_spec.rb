# frozen_string_literal: true

RSpec.describe TournamentsController, type: :request do
  describe '#edit' do
    let(:user) { create(:user) }
    let(:tournament) { create(:tournament, user: user) }
    let(:other_user) { create(:user) }

    context 'when user is signed in as tournament owner' do
      before do
        sign_in user
      end

      it 'returns tournament data' do
        get edit_tournament_path(tournament), as: :json

        expect(response).to be_successful
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'id' => tournament.id,
          'name' => tournament.name,
          'date' => tournament.date.to_s,
          'stream_url' => tournament.stream_url,
          'private' => tournament.private,
          'manual_seed' => tournament.manual_seed,
          'self_registration' => tournament.self_registration,
          'registration_open' => tournament.registration_open
        )
      end

      it 'includes form options data' do
        # Create some reference data
        create(:tournament_type, name: 'Store Championship')
        create(:format, name: 'Standard')
        create(:card_set, name: 'System Gateway')
        create(:deckbuilding_restriction, name: 'Standard Ban List')

        get edit_tournament_path(tournament), as: :json

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('tournament_types')
        expect(json_response).to have_key('formats')
        expect(json_response).to have_key('card_sets')
        expect(json_response).to have_key('deckbuilding_restrictions')

        # Verify the structure of the options
        expect(json_response['tournament_types'].first).to include('id', 'name')
        expect(json_response['formats'].first).to include('id', 'name')
        expect(json_response['card_sets'].first).to include('id', 'name')
        expect(json_response['deckbuilding_restrictions'].first).to include('id', 'name')
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
