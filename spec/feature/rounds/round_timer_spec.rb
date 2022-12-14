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
    end

    it 'hides the round timer when reset' do
      within(round_timer_form) do
        click_on 'Start'
        click_on 'Reset'
      end
      expect(page).to_not have_content(timer_display_message)
    end

    it 'shows the round timer when paused' do
      within(round_timer_form) do
        click_on 'Start'
        click_on 'Pause'
      end
      expect(find('.alert', text: timer_display_message)).to have_content("(paused)")
    end

    it 'pauses the round timer automatically when the round is completed' do
      within(round_timer_form) do
        travel_to Time.zone.local(2022, 8, 29, 15, 0)
        click_on 'Start'
      end
      travel_to Time.zone.local(2022, 8, 29, 15, 30)
      click_on 'Complete'
      expect(page).to_not have_content(timer_display_message)
      expect(round.timer.state).to have_attributes(paused: true, remaining_seconds: 35 * 60)
    end

    it 'does not show the timer form when the round is completed' do
      click_on 'Complete'
      expect(page).to_not have_selector(round_timer_form)
    end
  end

  def round_timer_form
    ".round-timer-form"
  end

  def timer_display_message
    "Remaining in swiss round 1"
  end

end
