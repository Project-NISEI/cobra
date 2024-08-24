# frozen_string_literal: true

RSpec.describe 'round timer service' do
  let(:tournament) { create(:tournament) }
  let(:round) { create(:round, stage: tournament.current_stage) }

  delegate :timer, to: :round

  it 'has a default round length' do
    expect(round.length_minutes).to be(65)
  end

  specify 'when timer is started, it is running' do
    travel_to Time.zone.local(2022, 8, 29, 15, 0)
    timer.start!
    expect(timer.state).to have_attributes(paused: false, finish_time: Time.zone.local(2022, 8, 29, 16, 5))
    expect(timer.running?).to be(true)
  end

  specify 'when timer is started and round has ended, timer is finished' do
    travel_to Time.zone.local(2022, 8, 29, 15, 0)
    timer.start!
    travel_to Time.zone.local(2022, 8, 29, 16, 10)
    expect(timer.state).to have_attributes(paused: false, finish_time: Time.zone.local(2022, 8, 29, 16, 5))
    expect(timer.running?).to be(false)
  end

  specify 'when timer is stopped after round has ended, timer is finished' do
    travel_to Time.zone.local(2022, 8, 29, 15, 0)
    timer.start!
    travel_to Time.zone.local(2022, 8, 29, 16, 10)
    timer.stop!
    expect(timer.state).to have_attributes(paused: false, finish_time: Time.zone.local(2022, 8, 29, 16, 5))
    expect(timer.running?).to be(false)
  end

  specify 'when timer is stopped before the end of the round, timer is paused' do
    travel_to Time.zone.local(2022, 8, 29, 15, 0)
    timer.start!
    travel_to Time.zone.local(2022, 8, 29, 15, 30)
    timer.stop!
    expect(timer.state).to have_attributes(paused: true, remaining_seconds: 35 * 60)
    expect(timer.running?).to be(false)
  end

  specify 'when timer is resumed, it is running' do
    travel_to Time.zone.local(2022, 8, 29, 15, 0)
    timer.start!
    travel_to Time.zone.local(2022, 8, 29, 15, 30)
    timer.stop!
    travel_to Time.zone.local(2022, 8, 29, 16, 0)
    timer.start!
    expect(timer.state).to have_attributes(paused: false, finish_time: Time.zone.local(2022, 8, 29, 16, 35))
    expect(timer.running?).to be(true)
  end

  specify 'when no timer started yet, it is not running' do
    expect(timer.state).to have_attributes(paused: false)
    expect(timer.running?).to be(false)
  end

  specify 'when no timer started yet, stopping it does nothing' do
    timer.stop!
    expect(timer.state).to have_attributes(paused: false)
    expect(timer.running?).to be(false)
  end
end
