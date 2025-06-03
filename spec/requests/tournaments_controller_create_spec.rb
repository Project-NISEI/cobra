# frozen_string_literal: true

RSpec.describe TournamentsController, type: :request do
  describe '#create' do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    context 'with valid parameters' do
      let(:valid_params) do
        {
          tournament: {
            name: 'Test Tournament',
            stream_url: 'https://twitch.tv',
            manual_seed: true
          }
        }
      end

      it 'creates a new tournament' do
        expect do
          post tournaments_path, params: valid_params, as: :json
        end.to change(Tournament, :count).by(1)
      end

      it 'creates a tournament with correct attributes' do
        post tournaments_path, params: valid_params, as: :json

        tournament = Tournament.last
        expect(tournament.name).to eq('Test Tournament')
        expect(tournament.stream_url).to eq('https://twitch.tv')
        expect(tournament.manual_seed?).to be(true)
        expect(tournament.user).to eq(user)
      end

      it 'returns success status with tournament data' do
        post tournaments_path, params: valid_params, as: :json

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(Tournament.last.id)
        expect(json_response['name']).to eq('Test Tournament')
        expect(json_response['url']).to be_present # URL to redirect to
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          tournament: {
            name: '' # Name is required
          }
        }
      end

      it 'does not create a new tournament' do
        expect do
          post tournaments_path, params: invalid_params, as: :json
        end.not_to change(Tournament, :count)
      end

      it 'returns unprocessable entity status with errors' do
        post tournaments_path, params: invalid_params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to be_present
        expect(json_response['errors']['name']).to include("can't be blank")
      end
    end

    context 'when user is not signed in' do
      before do
        sign_out
      end

      it 'returns unauthorized status' do
        post tournaments_path, params: { tournament: { name: 'Test Tournament' } }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not create a tournament' do
        expect do
          post tournaments_path, params: { tournament: { name: 'Test Tournament' } }, as: :json
        end.not_to change(Tournament, :count)
      end
    end

    context 'with additional tournament settings' do
      let(:tournament_type) { create(:tournament_type) }
      let(:format) { create(:format) }
      let(:card_set) { create(:card_set) }
      let(:restriction) { create(:deckbuilding_restriction) }

      let(:complete_params) do
        {
          tournament: {
            name: 'Complete Tournament',
            stream_url: 'https://twitch.tv',
            manual_seed: true,
            self_registration: true,
            private: true,
            tournament_type_id: tournament_type.id,
            format_id: format.id,
            card_set_id: card_set.id,
            deckbuilding_restriction_id: restriction.id,
            date: '2023-05-15'
          }
        }
      end

      it 'creates a tournament with all attributes' do
        post tournaments_path, params: complete_params, as: :json

        expect(response).to have_http_status(:created)
        tournament = Tournament.last
        expect(tournament.name).to eq('Complete Tournament')
        expect(tournament.stream_url).to eq('https://twitch.tv')
        expect(tournament.manual_seed?).to be(true)
        expect(tournament.self_registration?).to be(true)
        expect(tournament.private?).to be(true)
        expect(tournament.tournament_type_id).to eq(tournament_type.id)
        expect(tournament.format_id).to eq(format.id)
        expect(tournament.card_set_id).to eq(card_set.id)
        expect(tournament.deckbuilding_restriction_id).to eq(restriction.id)
        expect(tournament.date.to_s).to eq('2023-05-15')
      end
    end
  end
end