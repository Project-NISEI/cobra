# frozen_string_literal: true

RSpec.describe 'listing rounds' do
  let(:tournament) { create(:tournament) }
  let(:stage) { create(:stage, tournament:) }

  before do
    sign_in tournament.user
  end

  it 'is successful' do
    visit tournament_rounds_path(tournament)

    expect(page).to have_http_status :ok
  end

  context 'with multiple rounds' do
    let!(:round1) { create(:round, tournament:, stage: tournament.current_stage, number: 1) }
    let!(:round2) { create(:round, tournament:, stage: tournament.current_stage, number: 2) }

    it 'lists all rounds' do
      visit tournament_rounds_path(tournament)

      aggregate_failures do
        expect(page).to have_content('Round 1')
        expect(page).to have_content('Round 2')
      end
    end

    context 'with a lot of players' do
      before do
        round1.stage.players == create_list(:player, 120)
      end

      it 'lists all rounds when logged in as TO' do
        visit tournament_rounds_path(tournament)

        aggregate_failures do
          expect(page).to have_content('Round 1')
          expect(page).to have_content('Round 2')
          expect(page).not_to have_content('only the most recent round')
        end
      end

      it 'is inaccessible when not logged in as TO' do
        sign_in nil
        visit tournament_rounds_path(tournament)

        aggregate_failures do
          expect(page).to have_current_path(root_path, ignore_query: true)
          expect(page).to have_content("Sorry, you can't do that")
        end
      end
    end
  end
end
