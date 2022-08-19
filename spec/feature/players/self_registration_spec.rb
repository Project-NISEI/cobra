RSpec.describe 'registering for a tournament' do
  let(:organiser) { create(:user) }
  let(:player) { create(:user) }
  before do
    sign_in organiser
    visit new_tournament_path
    fill_in 'Tournament name', with: 'Test Tournament'
    check :tournament_self_registration
    click_button 'Create'
  end

  it 'registers player' do
    expect do
      register_player
    end.to change(Player, :count).by(1)
    expect(page.current_path).to eq(tournament_path(Tournament.last))
  end

  it 'registers player when tournament has no stages' do
    delete_tournament_stage

    expect do
      register_player
    end.to change(Player, :count).by(1)
    expect(page.current_path).to eq(tournament_path(Tournament.last))
  end

  def register_player
    sign_in player
    visit tournament_path(Tournament.last)
    fill_in :player_corp_identity, with: 'Haas-Bioroid: Engineering the Future'
    fill_in :player_runner_identity, with: 'Noise'
    click_button 'Register'
  end

  def delete_tournament_stage
    visit tournament_rounds_path(Tournament.last)
    click_on class: ['btn-danger']
  end

end
