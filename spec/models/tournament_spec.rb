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
                                             [identity, 2],
                                             [other_identity, 1]
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
                                               [identity, 1]
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

  describe '#build_player_summary' do
    let!(:tournament) { create(:tournament, swiss_format: :single_sided) }
    let!(:stage) { create(:stage, tournament:) }
    let!(:plural) { create(:player, tournament:, name: 'plural', first_round_bye: true) }
    let!(:gorphax) { create(:player, tournament:, name: 'gorphax') }
    let!(:cranked) { create(:player, tournament:, name: 'cranked') }
    let!(:orbital) { create(:player, tournament:, name: 'Orbital Tangent') }
    let!(:the_king) { create(:player, tournament:, name: 'The King') }

    it 'has player counts and defaults before any pairings' do
      thin_stuff = tournament.build_player_summary

      expect(thin_stuff).to eq({
                                 plural.id => ThinPlayer.new(plural.id, plural.name, true, true, 0, {}, 0, true),
                                 gorphax.id => ThinPlayer.new(gorphax.id, gorphax.name, true, false, 0, {}, 0, false),
                                 cranked.id => ThinPlayer.new(cranked.id, cranked.name, true, false, 0, {}, 0, false),
                                 orbital.id => ThinPlayer.new(orbital.id, orbital.name, true, false, 0, {}, 0, false),
                                 the_king.id => ThinPlayer.new(the_king.id, the_king.name, true, false, 0, {}, 0, false)
                               })
    end

    it 'has player counts and defaults for incomplete first round' do
      round = create(:round, stage:, tournament:, completed: false)

      create(:pairing, round:, player1: cranked, player2: the_king, side: 1)
      create(:pairing, round:, player1: gorphax, player2: orbital, side: 2)
      create(:pairing, round:, player1: plural, player2: nil)

      thin_stuff = tournament.build_player_summary

      expect(thin_stuff).to eq({
                                 plural.id => ThinPlayer.new(plural.id, plural.name, true, true, 0, {}, 0, true),
                                 gorphax.id => ThinPlayer.new(gorphax.id, gorphax.name, true, false, 0, {}, 0, false),
                                 cranked.id => ThinPlayer.new(cranked.id, cranked.name, true, false, 0, {}, 0, false),
                                 orbital.id => ThinPlayer.new(orbital.id, orbital.name, true, false, 0, {}, 0, false),
                                 the_king.id => ThinPlayer.new(the_king.id, the_king.name, true, false, 0, {}, 0, false)
                               })
    end

    it 'has player counts, scores and opponents for completed first round' do
      round = create(:round, stage:, tournament:, completed: true)

      create(:pairing, round:, player1: cranked, player2: the_king, side: 1, score1: 0, score2: 3)
      create(:pairing, round:, player1: gorphax, player2: orbital, side: 2, score1: 3, score2: 0)
      create(:pairing, round:, player1: plural, player2: nil, score1: 3)

      thin_stuff = tournament.build_player_summary

      expect(thin_stuff).to eq(
        {
          plural.id => ThinPlayer.new(plural.id, plural.name, true, true, 3, {}, 0, true),
          gorphax.id => ThinPlayer.new(gorphax.id, gorphax.name, true, false, 3, { orbital.id => ['runner'] }, -1,
                                       false),
          cranked.id => ThinPlayer.new(cranked.id, cranked.name, true, false, 0, { the_king.id => ['corp'] }, 1, false),
          orbital.id => ThinPlayer.new(orbital.id, orbital.name, true, false, 0, { gorphax.id => ['corp'] }, 1, false),
          the_king.id => ThinPlayer.new(the_king.id, the_king.name, true, false, 3, { cranked.id => ['runner'] }, -1,
                                        false)
        }
      )
    end

    it 'is unchanged for incomplete round >=1' do
      round1 = create(:round, stage:, tournament:, completed: true)
      create(:pairing, round: round1, player1: cranked, player2: the_king, side: 1, score1: 0, score2: 3)
      create(:pairing, round: round1, player1: gorphax, player2: orbital, side: 2, score1: 3, score2: 0)
      create(:pairing, round: round1, player1: plural, player2: nil, score1: 3)
      round2 = create(:round, stage:, tournament:, completed: false)
      create(:pairing, round: round2, player1: gorphax, player2: the_king, side: 2)
      create(:pairing, round: round2, player1: plural, player2: cranked, side: 1)
      create(:pairing, round: round2, player1: orbital, player2: nil)

      thin_stuff = tournament.build_player_summary

      expect(thin_stuff).to eq(
        {
          plural.id => ThinPlayer.new(plural.id, plural.name, true, true, 3, {}, 0, true),
          gorphax.id => ThinPlayer.new(gorphax.id, gorphax.name, true, false, 3, { orbital.id => ['runner'] }, -1,
                                       false),
          cranked.id => ThinPlayer.new(cranked.id, cranked.name, true, false, 0, { the_king.id => ['corp'] }, 1, false),
          orbital.id => ThinPlayer.new(orbital.id, orbital.name, true, false, 0, { gorphax.id => ['corp'] }, 1, false),
          the_king.id => ThinPlayer.new(the_king.id, the_king.name, true, false, 3, { cranked.id => ['runner'] }, -1,
                                        false)
        }
      )
    end

    it 'is updated for completed round 2' do
      round1 = create(:round, stage:, tournament:, completed: true)
      create(:pairing, round: round1, player1: cranked, player2: the_king, side: 1, score1: 0, score2: 3)
      create(:pairing, round: round1, player1: gorphax, player2: orbital, side: 2, score1: 3, score2: 0)
      create(:pairing, round: round1, player1: plural, player2: nil, score1: 3)
      round2 = create(:round, stage:, tournament:, completed: true)
      create(:pairing, round: round2, player1: gorphax, player2: the_king, side: 1, score1: 3, score2: 0)
      create(:pairing, round: round2, player1: plural, player2: cranked, side: 1, score1: 0, score2: 3)
      create(:pairing, round: round2, player1: orbital, player2: nil, score1: 3, score2: 0)

      thin_stuff = tournament.build_player_summary

      expect(thin_stuff).to eq(
        {
          plural.id => ThinPlayer.new(plural.id, plural.name, true, true, 3, { cranked.id => ['corp'] }, 1, true),
          gorphax.id => ThinPlayer.new(gorphax.id, gorphax.name, true, false, 6,
                                       { orbital.id => ['runner'], the_king.id => ['corp'] }, 0, false),
          cranked.id => ThinPlayer.new(cranked.id, cranked.name, true, false, 3,
                                       { the_king.id => ['corp'], plural.id => ['runner'] }, 0, false),
          orbital.id => ThinPlayer.new(orbital.id, orbital.name, true, false, 3, { gorphax.id => ['corp'] }, 1, true),
          the_king.id => ThinPlayer.new(the_king.id, the_king.name, true, false, 3,
                                        { cranked.id => ['runner'], gorphax.id => ['runner'] }, -2, false)
        }
      )
    end
  end
end
