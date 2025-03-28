# frozen_string_literal: true

RSpec.describe Tournament do
  let(:tournament) { create(:tournament, player_count: 4) }

  it 'automatically populates slug' do
    sample = create(:tournament, slug: nil)

    expect(sample).to be_valid
    expect(sample.slug).not_to be_nil
  end

  it 'does not overwrite slug' do
    expect do
      tournament.update(name: 'new name')
    end.not_to change(tournament, :slug)
  end

  it 'automatically populates date' do
    expect(tournament.date).to eq(Date.current)
  end

  it 'automatically creates stage' do
    expect do
      tournament
    end.to change(Stage, :count).by(1)

    stage = tournament.stages.last

    expect(stage.number).to eq(1)
    expect(stage.swiss?).to be(true)
  end

  context 'when tournament is created with alternative swiss format' do
    let(:tournament) { create(:tournament, swiss_format: :single_sided) }

    it 'automatically creates stage with correct format' do
      expect do
        tournament
      end.to change(Stage, :count).by(1)

      stage = tournament.stages.last

      expect(stage.number).to eq(1)
      expect(stage.single_sided_swiss?).to be(true)
    end
  end

  describe 'stream_url' do
    it 'has no stream_url by default' do
      expect(tournament.stream_url).to be_nil
    end

    it 'can have a stream_url set' do
      tournament.update(stream_url: 'https://twitch.tv')

      expect(tournament.stream_url).to eq('https://twitch.tv')
    end
  end

  describe '#corp_counts' do
    let!(:identity) { create(:identity, name: 'Something') }
    let!(:other_identity) { create(:identity, name: 'Something else') }

    before do
      tournament.players = [
        create(:player, corp_identity: 'Something'),
        create(:player, corp_identity: 'Something'),
        create(:player, corp_identity: 'Something else')
      ]
    end

    it 'returns counts' do
      expect(tournament.corp_counts).to eq([
                                             [identity, 2, 3],
                                             [other_identity, 1, 3]
                                           ])
    end
  end

  describe '#runner_counts' do
    let!(:identity) { create(:identity, name: 'Some runner') }

    before do
      tournament.players = [
        create(:player, runner_identity: 'Some runner')
      ]
    end

    it 'returns counts' do
      expect(tournament.runner_counts).to eq([
                                               [identity, 1, 1]
                                             ])
    end
  end

  describe '#cut_to!' do
    let(:tournament) { create(:tournament) }
    let(:swiss) { tournament.stages.first }
    let(:cut) do
      tournament.cut_to! :double_elim, 4
    end
    let(:alpha) { create(:player, tournament:, name: 'Alpha') }
    let(:bravo) { create(:player, tournament:, name: 'Bravo') }
    let(:charlie) { create(:player, tournament:, name: 'Charlie') }
    let(:delta) { create(:player, tournament:, name: 'Delta') }
    let(:echo) { create(:player, tournament:, name: 'Echo') }
    let(:foxtrot) { create(:player, tournament:, name: 'Foxtrot') }
    let(:round) { create(:round, stage: swiss, completed: true) }

    before do
      create(:pairing, round:, player1: alpha, player2: bravo, score1: 5, score2: 4)
      create(:pairing, round:, player1: charlie, player2: delta, score1: 3, score2: 2)
      create(:pairing, round:, player1: echo, player2: foxtrot, score1: 1, score2: 0)
    end

    it 'creates elim stage' do
      expect do
        cut
      end.to change(Stage, :count).by(1)

      new_stage = tournament.current_stage

      aggregate_failures do
        expect(new_stage.number).to eq(2)
        expect(new_stage.double_elim?).to be(true)
      end
    end

    it 'creates registrations' do
      aggregate_failures do
        expect(cut.seed(1)).to eq(alpha)
        expect(cut.seed(2)).to eq(bravo)
        expect(cut.seed(3)).to eq(charlie)
        expect(cut.seed(4)).to eq(delta)
      end
    end
  end

  describe '#id_and_faction_data' do
    it 'returns correct default data for fresh, empty tournament' do
      tournament = create(:tournament)
      expect(tournament.id_and_faction_data).to eq({
                                                     corp: { factions: {},
                                                             ids: {} },
                                                     cut: { corp: { factions: {}, ids: {} }, num_players: 0,
                                                            runner: { factions: {}, ids: {} } },
                                                     num_players: 0,
                                                     runner: { factions: {},
                                                               ids: {} }
                                                   })
    end

    it 'returns correct default data for tournament with players before first round is paired' do
      expect(tournament.players.count).to eq(4)
      expect(tournament.id_and_faction_data).to eq({
                                                     corp: { factions: {},
                                                             ids: {} },
                                                     cut: { corp: { factions: {}, ids: {} }, num_players: 0,
                                                            runner: { factions: {}, ids: {} } },
                                                     num_players: 0,
                                                     runner: { factions: {},
                                                               ids: {} }
                                                   })
    end

    it 'returns correct data for basic players without identities set' do
      swiss = tournament.stages.first
      round = create(:round, stage: swiss)
      create(:pairing, round:, player1: tournament.players[0], player2: tournament.players[1])
      create(:pairing, round:, player1: tournament.players[2], player2: tournament.players[3])

      expect(tournament.id_and_faction_data).to eq({
                                                     corp: { factions: { 'unspecified' => 4 },
                                                             ids: { 'Unspecified' => { count: 4,
                                                                                       faction: 'unspecified' } } },
                                                     cut: { corp: { factions: {}, ids: {} }, num_players: 0,
                                                            runner: { factions: {}, ids: {} } },
                                                     num_players: 4,
                                                     runner: { factions: { 'unspecified' => 4 },
                                                               ids: { 'Unspecified' => { count: 4,
                                                                                         faction: 'unspecified' } } }
                                                   })
    end

    it 'returns correct data for swiss and for cut' do
      precision_design = create(:identity, side: 1, name: 'Precision Design', faction: 'haas-bioroid')
      epiphany = create(:identity, side: 1, name: 'Epiphany', faction: 'nbn')
      maxx = create(:identity, side: 2, name: 'Maxx', faction: 'anarch')
      smoke = create(:identity, side: 2, name: 'Smoke', faction: 'shaper')

      # Add 6 more players with ids in addition to the 4 players already created without ids.
      alpha = create(:player, tournament:, name: 'Alpha',
                              corp_identity_ref_id: precision_design.id,
                              runner_identity_ref_id: smoke.id)

      bravo = create(:player, tournament:, name: 'Bravo',
                              corp_identity_ref_id: epiphany.id,
                              runner_identity_ref_id: maxx.id)

      charlie = create(:player, tournament:, name: 'Charlie',
                                corp_identity_ref_id: precision_design.id,
                                runner_identity_ref_id: maxx.id)

      delta = create(:player, tournament:, name: 'Delta')
      echo = create(:player, tournament:, name: 'Echo')
      foxtrot = create(:player, tournament:, name: 'Foxtrot')

      swiss = tournament.stages.first
      round = create(:round, stage: swiss, completed: true)
      create(:pairing, round:, player1: alpha, player2: bravo, score1: 6, score1_corp: 3, score1_runner: 3, score2: 0,
                       score2_corp: 0, score2_runner: 0)
      create(:pairing, round:, player1: charlie, player2: delta, score1: 3, score1_corp: 0, score1_runner: 3,
                       score2: 3, score2_corp: 0, score2_runner: 3)
      create(:pairing, round:, player1: echo, player2: foxtrot, score1: 1, score2: 0)

      expect(tournament.id_and_faction_data).to eq(
        {
          corp: { factions: { 'haas-bioroid' => 2, 'nbn' => 1, 'unspecified' => 7 },
                  ids: { 'Epiphany' => { count: 1, faction: 'nbn' },
                         'Precision Design' => { count: 2, faction: 'haas-bioroid' },
                         'Unspecified' => { count: 7, faction: 'unspecified' } } },
          cut: { corp: { factions: {}, ids: {} }, num_players: 0,
                 runner: { factions: {}, ids: {} } },
          num_players: 10,
          runner: { factions: { 'anarch' => 2, 'shaper' => 1, 'unspecified' => 7 },
                    ids: { 'Maxx' => { count: 2, faction: 'anarch' },
                           'Smoke' => { count: 1, faction: 'shaper' },
                           'Unspecified' => { count: 7, faction: 'unspecified' } } }
        }
      )

      tournament.cut_to! :double_elim, 4

      expect(tournament.id_and_faction_data).to eq(
        {
          corp: { factions: { 'haas-bioroid' => 2, 'nbn' => 1, 'unspecified' => 7 },
                  ids: { 'Epiphany' => { count: 1, faction: 'nbn' },
                         'Precision Design' => { count: 2, faction: 'haas-bioroid' },
                         'Unspecified' => { count: 7, faction: 'unspecified' } } },
          cut: {
            corp: { factions: { 'haas-bioroid' => 2, 'unspecified' => 2 },
                    ids: { 'Precision Design' => { count: 2, faction: 'haas-bioroid' },
                           'Unspecified' => { count: 2,
                                              faction: 'unspecified' } } },
            num_players: 4,
            runner: { factions: { 'anarch' => 1, 'shaper' => 1, 'unspecified' => 2 },
                      ids: { 'Maxx' => { count: 1, faction: 'anarch' },
                             'Smoke' => { count: 1, faction: 'shaper' },
                             'Unspecified' => { count: 2, faction: 'unspecified' } } }
          },
          num_players: 10,
          runner: { factions: { 'anarch' => 2, 'shaper' => 1, 'unspecified' => 7 },
                    ids: { 'Maxx' => { count: 2, faction: 'anarch' },
                           'Smoke' => { count: 1, faction: 'shaper' },
                           'Unspecified' => { count: 7, faction: 'unspecified' } } }
        }
      )
    end
  end

  describe '#side_win_percentages' do
    let(:tournament) { create(:tournament) }
    let(:swiss) { tournament.stages.first }
    let(:cut) do
      tournament.cut_to! :double_elim, 4
    end
    let(:cut_stage) { tournament.stages.second }
    let(:alpha) { create(:player, tournament:, name: 'Alpha') }
    let(:bravo) { create(:player, tournament:, name: 'Bravo') }
    let(:charlie) { create(:player, tournament:, name: 'Charlie') }
    let(:delta) { create(:player, tournament:, name: 'Delta') }
    let(:echo) { create(:player, tournament:, name: 'Echo') }
    let(:foxtrot) { create(:player, tournament:, name: 'Foxtrot') }

    let(:round) { create(:round, stage: swiss, completed: true) }
    let(:cut_round) { create(:round, stage: cut_stage, completed: true) }

    before do
      create(:pairing, round:, player1: alpha, player2: bravo, score1: 6, score1_corp: 3, score1_runner: 3, score2: 0,
                       score2_corp: 0, score2_runner: 0)
      create(:pairing, round:, player1: charlie, player2: delta, score1: 3, score1_corp: 0, score1_runner: 3,
                       score2: 3, score2_corp: 0, score2_runner: 3)
      create(:pairing, round:, player1: echo, player2: foxtrot, score1: 1, score2: 0)
    end

    it 'returns correct complete and incomplete games for swiss' do
      aggregate_failures do
        expect(tournament.side_win_percentages_data).to eq(
          [
            {
              stage_number: 1,
              num_games: 6,
              num_valid_games: 4,
              valid_game_percentage: (4 / 6.0) * 100,
              num_corp_wins: 1,
              corp_win_percentage: (1 / 4.0) * 100,
              num_runner_wins: 3,
              runner_win_percentage: (3 / 4.0) * 100
            }
          ]
        )
      end
    end

    it 'returns correct games for cut' do
      cut
      cut_stage = tournament.current_stage
      cut_stage.pair_new_round!

      create(:pairing, round: cut_round, side: 1, player1: alpha, player2: foxtrot,
                       score1: 0, score1_corp: 0, score1_runner: 0,
                       score2: 3, score2_corp: 0, score2_runner: 3)
      create(:pairing, round: cut_round, side: 1, player1: charlie, player2: delta,
                       score1: 3, score1_corp: 3, score1_runner: 0,
                       score2: 0, score2_corp: 0, score2_runner: 0)

      expect(tournament.side_win_percentages_data).to eq(
        [
          {
            stage_number: 1,
            num_games: 6,
            num_valid_games: 4,
            valid_game_percentage: (4 / 6.0) * 100,
            num_corp_wins: 1,
            corp_win_percentage: (1 / 4.0) * 100,
            num_runner_wins: 3,
            runner_win_percentage: (3 / 4.0) * 100
          },
          {
            stage_number: 2,
            num_games: 2,
            num_valid_games: 2,
            valid_game_percentage: 100,
            num_corp_wins: 1,
            corp_win_percentage: 50,
            num_runner_wins: 1,
            runner_win_percentage: 50
          }

        ]
      )
    end
  end

  describe '#current_stage' do
    let!(:new_stage) { create(:stage, tournament:, number: 2) }

    it 'returns last stage' do
      expect(tournament.current_stage).to eq(new_stage)
    end
  end

  describe '#cut_conversion_rates_data' do
    let(:tournament) { create(:tournament) }
    let(:round) { create(:round, stage: swiss, completed: true) }
    let(:swiss) { tournament.stages.first }
    let(:cut) do
      tournament.cut_to! :double_elim, 4
    end

    let(:precision_design) { create(:identity, side: 1, name: 'Precision Design', faction: 'haas-bioroid') }
    let(:epiphany) { create(:identity, side: 1, name: 'Epiphany', faction: 'nbn') }
    let(:maxx) { create(:identity, side: 2, name: 'Maxx', faction: 'anarch') }
    let(:smoke) { create(:identity, side: 2, name: 'Smoke', faction: 'shaper') }

    let(:alpha) do
      create(:player, tournament:, name: 'Alpha', corp_identity_ref_id: precision_design.id,
                      runner_identity_ref_id: smoke.id)
    end
    let(:bravo) do
      create(:player, tournament:, name: 'Bravo', corp_identity_ref_id: epiphany.id, runner_identity_ref_id: maxx.id)
    end
    let(:charlie) do
      create(:player, tournament:, name: 'Charlie', corp_identity_ref_id: precision_design.id,
                      runner_identity_ref_id: maxx.id)
    end
    let(:delta) { create(:player, tournament:, name: 'Delta') }
    let(:echo) { create(:player, tournament:, name: 'Echo') }
    let(:foxtrot) { create(:player, tournament:, name: 'Foxtrot') }

    it 'returns correct default data for fresh, empty tournament' do
      expect(tournament.cut_conversion_rates_data).to eq(
        { factions: { corp: {}, runner: {} }, identities: { corp: {}, runner: {} } }
      )
    end

    it 'returns correct data before cut' do
      create(:pairing, round:, player1: alpha, player2: bravo, score1: 5, score2: 4)
      create(:pairing, round:, player1: charlie, player2: delta, score1: 3, score2: 2)
      create(:pairing, round:, player1: echo, player2: foxtrot, score1: 1, score2: 0)

      expect(tournament.cut_conversion_rates_data).to eq(
        {
          factions: {
            corp: {
              'haas-bioroid' => { num_swiss_players: 2, num_cut_players: 0, cut_conversion_percentage: 0.0 },
              'nbn' => { num_swiss_players: 1, num_cut_players: 0, cut_conversion_percentage: 0.0 },
              'Unspecified' => { num_swiss_players: 3, num_cut_players: 0, cut_conversion_percentage: 0.0 }
            },
            runner: {
              'anarch' => { num_swiss_players: 2, num_cut_players: 0, cut_conversion_percentage: 0.0 },
              'shaper' => { num_swiss_players: 1, num_cut_players: 0, cut_conversion_percentage: 0.0 },
              'Unspecified' => { num_swiss_players: 3, num_cut_players: 0, cut_conversion_percentage: 0.0 }
            }
          },
          identities: {
            corp: {
              'Epiphany' => { num_swiss_players: 1, num_cut_players: 0,
                              cut_conversion_percentage: 0.0 },
              'Precision Design' => { num_swiss_players: 2, num_cut_players: 0,
                                      cut_conversion_percentage: 0.0 },
              'Unspecified' => { num_swiss_players: 3, num_cut_players: 0, cut_conversion_percentage: 0.0 }
            },
            runner: {
              'Unspecified' => { num_swiss_players: 3, num_cut_players: 0, cut_conversion_percentage: 0.0 },
              'Maxx' => { num_swiss_players: 2, num_cut_players: 0, cut_conversion_percentage: 0.0 },
              'Smoke' => { num_swiss_players: 1, num_cut_players: 0, cut_conversion_percentage: 0.0 }
            }
          }
        }
      )
    end

    it 'returns correct data after cut' do
      create(:pairing, round:, player1: alpha, player2: bravo, score1: 5, score2: 4)
      create(:pairing, round:, player1: charlie, player2: delta, score1: 3, score2: 2)
      create(:pairing, round:, player1: echo, player2: foxtrot, score1: 1, score2: 0)

      cut

      expect(tournament.cut_conversion_rates_data).to eq(
        {
          factions: {
            corp: {
              'haas-bioroid' => { num_swiss_players: 2, num_cut_players: 2, cut_conversion_percentage: 100.0 },
              'nbn' => { num_swiss_players: 1, num_cut_players: 1, cut_conversion_percentage: 100.0 },
              'Unspecified' => { num_swiss_players: 3, num_cut_players: 1,
                                 cut_conversion_percentage: ((1 / 3.0) * 100).floor(2) }
            },
            runner: {
              'anarch' => { num_swiss_players: 2, num_cut_players: 2, cut_conversion_percentage: 100.0 },
              'shaper' => { num_swiss_players: 1, num_cut_players: 1, cut_conversion_percentage: 100.0 },
              'Unspecified' => { num_swiss_players: 3, num_cut_players: 1,
                                 cut_conversion_percentage: ((1 / 3.0) * 100).floor(2) }
            }
          },
          identities: {
            corp: {
              'Epiphany' => { num_swiss_players: 1, num_cut_players: 1,
                              cut_conversion_percentage: 100.0 },
              'Precision Design' => { num_swiss_players: 2, num_cut_players: 2,
                                      cut_conversion_percentage: 100.0 },
              'Unspecified' => { num_swiss_players: 3, num_cut_players: 1,
                                 cut_conversion_percentage: ((1 / 3.0) * 100).floor(2) }
            },
            runner: {
              'Unspecified' => { num_swiss_players: 3, num_cut_players: 1,
                                 cut_conversion_percentage: ((1 / 3.0) * 100).floor(2) },
              'Maxx' => { num_swiss_players: 2, num_cut_players: 2, cut_conversion_percentage: 100.0 },
              'Smoke' => { num_swiss_players: 1, num_cut_players: 1, cut_conversion_percentage: 100.0 }
            }
          }
        }
      )
    end
  end
end
