RSpec.describe 'round timer' do
  let(:tournament) { create(:tournament) }
  let(:round) { create(:round, stage: tournament.current_stage) }

  context 'viewing tournament rounds as the tournament creator' do
    before do
      sign_in round.tournament.user
      visit tournament_rounds_path(round.tournament)
    end

    it 'shows the round timer when started' do
      within(round_timer_form) {click_on 'Start'}
      expect(page).to have_content(timer_display_message)
    end

    it 'does not show the round timer if not started' do
      expect(page).to_not have_content(timer_display_message)
      expect(page).to_not have_content(timer_paused_message)
    end

    it 'hides the round timer when reset' do
      within(round_timer_form) do
        click_on 'Start'
        click_on 'Reset'
      end
      expect(page).to_not have_content(timer_display_message)
      expect(page).to_not have_content(timer_paused_message)
    end

    it 'shows the round timer when paused' do
      within(round_timer_form) do
        click_on 'Start'
        click_on 'Pause'
      end
      expect(page).to have_content(timer_paused_message)
    end
  end

  def round_timer_form
    ".round-timer-form"
  end

  def timer_display_message
    "Remaining in round 1:"
  end

  def timer_paused_message
    "Round 1 paused, remaining:"
  end
end
