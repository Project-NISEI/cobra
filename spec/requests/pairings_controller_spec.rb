# frozen_string_literal: true

RSpec.describe PairingsController do
  describe 'pairings data' do
    let(:organiser) { create(:user) }
    let!(:alice_nrdb) { create(:user) }
    let!(:bob_nrdb) { create(:user) }
    let!(:charlie_nrdb) { create(:user) }

    let(:tournament_self_reporting_disabled) { create(:tournament, name: 'My Tournament 1', user: organiser) }

    let(:tournament) { create(:tournament, name: 'My Tournament 2', user: organiser, allow_self_reporting: true) }

    describe 'when self reporting is disabled' do
      let!(:alice) do
        create(:player, tournament: tournament_self_reporting_disabled, name: 'Alice', pronouns: 'she/her',
                        user_id: alice_nrdb.id)
      end
      let!(:bob) do
        create(:player, tournament: tournament_self_reporting_disabled, name: 'Bob', pronouns: 'he/him',
                        user_id: bob_nrdb.id)
      end
      let!(:charlie) do
        create(:player, tournament: tournament_self_reporting_disabled, name: 'Charlie', pronouns: 'she/her')
      end

      before do
        Pairer.new(tournament_self_reporting_disabled.new_round!, Random.new(0)).pair!
      end

      it 'return unauthorized when not logged in' do
        sign_in nil

        post self_report_tournament_round_pairing_path(tournament_self_reporting_disabled,
                                                       tournament_self_reporting_disabled.rounds[0],
                                                       tournament_self_reporting_disabled.rounds[0].pairings[0]),
             params: {}, as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'return unauthorized when logged in' do
        sign_in bob_nrdb

        post self_report_tournament_round_pairing_path(tournament_self_reporting_disabled,
                                                       tournament_self_reporting_disabled.rounds[0],
                                                       tournament_self_reporting_disabled.rounds[0].pairings[0]),
             params: {}, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe 'when self reporting is enabled' do
      let!(:alice) { create(:player, tournament:, name: 'Alice', pronouns: 'she/her', user_id: alice_nrdb.id) }
      let!(:bob) { create(:player, tournament:, name: 'Bob', pronouns: 'he/him', user_id: bob_nrdb.id) }
      let!(:charlie) { create(:player, tournament:, name: 'Charlie', pronouns: 'she/her') }

      before do
        Pairer.new(tournament.new_round!, Random.new(0)).pair!
      end

      it 'return unauthorized when not logged in' do
        sign_in nil

        post self_report_tournament_round_pairing_path(tournament,
                                                       tournament.rounds[0],
                                                       tournament.rounds[0].pairings[0]),
             params: {}, as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'return unauthorized when logged in user is not part of pairing' do
        sign_in alice_nrdb

        post self_report_tournament_round_pairing_path(tournament,
                                                       tournament.rounds[0],
                                                       tournament.rounds[0].pairings[0]),
             params: {}, as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'create self report and returns status ok' do
        sign_in bob_nrdb

        expect do
          post self_report_tournament_round_pairing_path(tournament,
                                                         tournament.rounds[0],
                                                         tournament.rounds[0].pairings[0]),
               params: create_pairing_params, as: :json
        end.to change(SelfReport, :count).by(1)

        expect(response).to have_http_status(:ok)
      end

      it 'returns forbidden when user already reported' do
        sign_in bob_nrdb
        expect do
          post self_report_tournament_round_pairing_path(tournament,
                                                         tournament.rounds[0],
                                                         tournament.rounds[0].pairings[0]),
               params: create_pairing_params, as: :json
          post self_report_tournament_round_pairing_path(tournament,
                                                         tournament.rounds[0],
                                                         tournament.rounds[0].pairings[0]),
               params: create_pairing_params, as: :json
        end.to change(SelfReport, :count).by(1)

        expect(response).to have_http_status(:forbidden)
      end
    end

    def create_pairing_params(overrides = {})
      {
        pairing: {
          score1_runner: 3,
          score1_corp: 0,
          score2_runner: 0,
          score2_corp: 3,
          score1: 3,
          score2: 0,
          intentional_draw: false
        }.merge(overrides)
      }
    end
  end
end
