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
      puts tournament.cut_conversion_rates_data.inspect
      expect(tournament.cut_conversion_rates_data).to eq(
        { factions: { corp: {}, runner: {} }, identities: { corp: {}, runner: {} } }
      )
    end

    it 'returns correct data before cut' do
      create(:pairing, round:, player1: alpha, player2: bravo, score1: 5, score2: 4)
      create(:pairing, round:, player1: charlie, player2: delta, score1: 3, score2: 2)
      create(:pairing, round:, player1: echo, player2: foxtrot, score1: 1, score2: 0)

      puts tournament.cut_conversion_rates_data.inspect
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

      puts tournament.cut_conversion_rates_data.inspect
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

# -:identities => {:corp=>{"Epiphany"=>{:cut_conversion_percentage=>100.0, :num_cut_players=>1, :num_swiss_players=>1}, "Precision Design"=>{:cut_conversion_percentage=>100.0, :num_cut_players=>1, :num_swiss_players=>2}, "Unspecified"=>{:cut_conversion_percentage=>33.33333333333333,  :num_cut_players=>1, :num_swiss_players=>3}}, :runner=>{"Maxx"=>{:cut_conversion_percentage=>100.0, :num_cut_players=>2, :num_swiss_players=>2}, "Smoke"=>{:cut_conversion_percentage=>100.0, :num_cut_players=>1, :num_swiss_players=>1}, "Unspecified"=>{:cut_conversion_percentage=>33.33333333333333,  :num_cut_players=>1, :num_swiss_players=>3}}},
# +:identities => {:corp=>{"Epiphany"=>{:cut_conversion_percentage=>100.0, :num_cut_players=>1, :num_swiss_players=>1}, "Precision Design"=>{:cut_conversion_percentage=>100.0, :num_cut_players=>2, :num_swiss_players=>2}, "Unspecified"=>{:cut_conversion_percentage=>33.333333333333336, :num_cut_players=>1, :num_swiss_players=>3}}, :runner=>{"Maxx"=>{:cut_conversion_percentage=>100.0, :num_cut_players=>2, :num_swiss_players=>2}, "Smoke"=>{:cut_conversion_percentage=>100.0, :num_cut_players=>1, :num_swiss_players=>1}, "Unspecified"=>{:cut_conversion_percentage=>33.333333333333336, :num_cut_players=>1, :num_swiss_players=>3}}},
