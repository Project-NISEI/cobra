RSpec.describe 'a completed top cut with a player with no seed' do
  let(:tournament) { create(:tournament) }

  before do
    tournament.players << create(
      :player,
      name: 'Alice',
      corp_identity: 'A Corp',
      runner_identity: 'A Runner'
    )
    tournament.players << create(
      :player,
      name: 'Bob',
      corp_identity: 'Best Corp',
      runner_identity: 'Best Runner'
    )
    tournament.players << create(
      :player,
      name: 'Carl',
      corp_identity: 'Cool Corp',
      runner_identity: 'Cool Runner'
    )
    tournament.players << create(
      :player,
      name: 'Doris',
      corp_identity: 'Dope Corp',
      runner_identity: 'Dope Runner'
    )
    tournament.players << create(
      :player,
      name: 'Emily',
      corp_identity: 'Excellent Corp',
      runner_identity: 'Excellent Runner'
    )

    sign_in tournament.user
    tournament.pair_new_round!
    set_round_score1_and_complete 1, 6
    tournament.cut_to!(:double_elim, 4)
    tournament.pair_new_round!
    cut_round_1 = round_number(1)
    @unseeded = cut_round_1.unpaired_players.first
    set_table_player1(cut_round_1, 1, @unseeded)
    set_round_score1_and_pair_new 1, 3
    set_round_score1_and_pair_new 2, 3
    set_round_score1_and_pair_new 3, 3
    set_round_score1_and_pair_new 4, 3
    set_round_score1_and_complete 5, 3
  end

  it 'loads tournament standings with player names' do
    get standings_data_tournament_players_path(tournament)
    aggregate_failures do
      expect(response.body).to include('Alice')
      expect(response.body).to include('Bob')
      expect(response.body).to include('Carl')
      expect(response.body).to include('Doris')
      expect(response.body).to include('Emily')
    end
  end

  it 'generates NRTM data for the tournament' do
    expect(NrtmJson.new(tournament).data('https://server/SLUG')[:eliminationPlayers]
             .map { |player| [player[:rank], player[:seed]] })
      .to eq([[1, nil], [2, 2], [3, 4], [4, 3]])
  end

  def round_number(round_number)
    tournament.current_stage.rounds.find_by(number: round_number)
  end

  def set_round_score1_and_pair_new(round_number, score1)
    set_round_score1_and_complete round_number, score1
    tournament.pair_new_round!
  end

  def set_round_score1_and_complete(round_number, score1)
    round = round_number(round_number)
    round.pairings.each { |pairing| pairing.update({ score1: score1, score2: 0 }) }
    round.update(completed: true)
  end

  def set_table_player1(round, table_number, player)
    delete_pairing = round.pairings.find_by(table_number: table_number)
    player_2 = delete_pairing.player2
    side = delete_pairing.side
    delete_pairing.destroy
    round.pairings.create(player1: player, player2: player_2, table_number: 1, side: side)
  end
end
