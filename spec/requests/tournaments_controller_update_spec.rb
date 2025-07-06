# frozen_string_literal: true

RSpec.describe TournamentsController, type: :request do
  describe '#update' do
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
      Tournament.last
    end

    before do
      tournament
    end

    context 'with valid parameters' do
      it 'edits a tournament' do
        patch tournament_path(tournament), params: { tournament: { name: 'Edited Tournament' } }, as: :json

        tournament.reload
        expect(tournament).to have_attributes(
          name: 'Edited Tournament',
          user_id: user.id
        )

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
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

      it 'does not edit a tournament' do
        patch tournament_path(tournament), params: invalid_params, as: :json
        tournament.reload
        expect(tournament).to have_attributes(name: 'Test Tournament')
      end

      it 'returns unprocessable entity status with errors' do
        patch tournament_path(tournament), params: invalid_params, as: :json

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
        patch tournament_path(tournament), params: { tournament: { name: 'Edited Tournament' } }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not edit a tournament' do
        patch tournament_path(tournament), params: { tournament: { name: 'Edited Tournament' } }, as: :json
        tournament.reload
        expect(tournament).to have_attributes(name: 'Test Tournament')
      end
    end

    context 'with additional tournament settings' do
      let(:tournament_type) { create(:tournament_type) }
      let(:format) { create(:format) }
      let(:card_set) { create(:card_set) }
      let(:restriction) { create(:deckbuilding_restriction) }

      it 'edits a tournament with more attributes' do
        patch tournament_path(tournament), params: {
          tournament: {
            name: 'Extended Tournament',
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

        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
        tournament.reload
        expect(tournament).to have_attributes(
          name: 'Extended Tournament',
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
