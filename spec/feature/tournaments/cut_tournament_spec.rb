# frozen_string_literal: true

RSpec.describe 'cutting tournament' do
  let(:tournament) do
    create(:tournament, player_count: 10)
  end

  context 'as guest' do
    context 'on rounds page' do
      before do
        visit tournament_rounds_path(tournament)
      end

      it 'does not display link' do
        expect(page).not_to have_content('Cut to Top')
      end
    end
  end

  context 'as tournament owner' do
    before do
      sign_in tournament.user
    end

    context 'on settings page' do
      before do
        visit edit_tournament_path(tournament)
      end

      it 'creates double elim stage' do
        expect do
          click_button 'Cut to Top 4'
        end.to change(tournament.stages, :count).by(1)
      end
    end

    context 'on rounds page' do
      before do
        visit tournament_rounds_path(tournament)
      end

      it 'creates double elim stage' do
        expect(tournament.stages.size).to eq(1)

        click_link 'Double-Elimination Top 8'

        expect(tournament.stages.size).to eq(2)
        expect(tournament.stages.last.format).to eq('double_elim')
      end

      it 'creates single elim stage' do
        expect(tournament.stages.size).to eq(1)

        click_link 'Single-Elimination Top 4'

        expect(tournament.stages.size).to eq(2)
        expect(tournament.stages.last.format).to eq('single_elim')
      end
    end
  end
end
