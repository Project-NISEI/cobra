# frozen_string_literal: true

RSpec.describe TournamentsController, type: :request do
  describe '#create' do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    context 'with valid parameters' do
      it 'creates a new tournament' do
        expect do
          post tournaments_path, params: { tournament: { name: 'Test Tournament' } }, as: :json
        end.to change(Tournament, :count).by(1)

        tournament = Tournament.last
        expect(tournament).to have_attributes(
          name: 'Test Tournament',
          user_id: user.id
        )

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to eq(
          {
            'id' => tournament.id,
            'name' => 'Test Tournament',
            'url' => tournament_path(tournament)
          }
        )
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
        expect(JSON.parse(response.body)).to eq(
          {
            'errors' => { 'name' => ["can't be blank"] }
          }
        )
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

      it 'creates a tournament with more attributes' do
        post tournaments_path, params: {
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
        }, as: :json

        expect(response).to have_http_status(:created)
        expect(Tournament.last).to have_attributes(
          name: 'Complete Tournament',
          stream_url: 'https://twitch.tv',
          user_id: user.id,
          manual_seed: true,
          self_registration: true,
          private: true,
          tournament_type_id: tournament_type.id,
          format_id: format.id,
          card_set_id: card_set.id,
          deckbuilding_restriction_id: restriction.id,
          date: Date.parse('2023-05-15')
        )
      end
    end
  end
end
