# frozen_string_literal: true

RSpec.describe PairingStrategies::Base do
  let(:strategy) { create(PairingStrategies::Base()) }

  describe '#build_player_summary' do
    let!(:tournament) { create(:tournament, swiss_format: :single_sided) }
    let!(:stage) { create(:stage, tournament:) }
    let!(:plural) { create(:player, tournament:, name: 'plural', first_round_bye: true) }
    let!(:gorphax) { create(:player, tournament:, name: 'gorphax') }
    let!(:cranked) { create(:player, tournament:, name: 'cranked') }
    let!(:orbital) { create(:player, tournament:, name: 'Orbital Tangent') }
    let!(:the_king) { create(:player, tournament:, name: 'The King') }

    it 'has player counts and defaults for incomplete first round' do
      round = create(:round, stage:, tournament:, completed: false)

      pairer = described_class.new(round, Random.new(1000))
      create(:pairing, round:, player1: cranked, player2: the_king, side: 1)
      create(:pairing, round:, player1: gorphax, player2: orbital, side: 2)
      create(:pairing, round:, player1: plural, player2: nil)

      thin_stuff = pairer.build_player_summary

      expect(thin_stuff).to eq({
                                 plural.id => PairingStrategies::PlainPlayer.new(plural.id, plural.name, true, true),
                                 gorphax.id => PairingStrategies::PlainPlayer.new(gorphax.id, gorphax.name, true,
                                                                                  false),
                                 cranked.id => PairingStrategies::PlainPlayer.new(cranked.id, cranked.name, true,
                                                                                  false),
                                 orbital.id => PairingStrategies::PlainPlayer.new(orbital.id, orbital.name, true,
                                                                                  false),
                                 the_king.id => PairingStrategies::PlainPlayer.new(the_king.id, the_king.name, true,
                                                                                   false)
                               })
    end

    it 'has player counts, scores and opponents for completed first round' do
      round = create(:round, stage:, tournament:, completed: true)

      create(:pairing, round:, player1: cranked, player2: the_king, side: 1, score1: 0, score2: 3)
      create(:pairing, round:, player1: gorphax, player2: orbital, side: 2, score1: 3, score2: 0)
      create(:pairing, round:, player1: plural, player2: nil, score1: 3)

      pairer = described_class.new(round, Random.new(1000))

      thin_stuff = pairer.build_player_summary

      expect(thin_stuff).to eq(
        {
          plural.id => PairingStrategies::PlainPlayer.new(plural.id, plural.name, true, true, points: 3),
          gorphax.id => PairingStrategies::PlainPlayer.new(gorphax.id, gorphax.name, true, false,
                                                           opponents: { orbital.id => ['runner'] },
                                                           points: 3, side_bias: -1),
          cranked.id => PairingStrategies::PlainPlayer.new(cranked.id, cranked.name, true, false,
                                                           opponents: { the_king.id => ['corp'] }, side_bias: 1),
          orbital.id => PairingStrategies::PlainPlayer.new(orbital.id, orbital.name, true, false,
                                                           opponents: { gorphax.id => ['corp'] }, side_bias: 1),
          the_king.id => PairingStrategies::PlainPlayer.new(the_king.id, the_king.name, true, false,
                                                            opponents: { cranked.id => ['runner'] },
                                                            side_bias: -1, points: 3)
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

      pairer = described_class.new(round2, Random.new(1000))
      thin_stuff = pairer.build_player_summary

      expect(thin_stuff).to eq(
        {
          plural.id => PairingStrategies::PlainPlayer.new(plural.id, plural.name, true, true, points: 3),
          gorphax.id => PairingStrategies::PlainPlayer.new(gorphax.id, gorphax.name, true, false,
                                                           opponents: { orbital.id => ['runner'] },
                                                           points: 3, side_bias: -1),
          cranked.id => PairingStrategies::PlainPlayer.new(cranked.id, cranked.name, true, false,
                                                           opponents: { the_king.id => ['corp'] }, side_bias: 1),
          orbital.id => PairingStrategies::PlainPlayer.new(orbital.id, orbital.name, true, false,
                                                           opponents: { gorphax.id => ['corp'] }, side_bias: 1),
          the_king.id => PairingStrategies::PlainPlayer.new(the_king.id, the_king.name, true, false,
                                                            opponents: { cranked.id => ['runner'] },
                                                            points: 3, side_bias: -1)
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

      pairer = described_class.new(round2, Random.new(1000))
      thin_stuff = pairer.build_player_summary

      expect(thin_stuff).to eq(
        {
          plural.id => PairingStrategies::PlainPlayer.new(plural.id, plural.name, true, true,
                                                          opponents: { cranked.id => ['corp'] },
                                                          side_bias: 1, points: 3),
          gorphax.id => PairingStrategies::PlainPlayer.new(gorphax.id, gorphax.name, true, false,
                                                           opponents: {
                                                             orbital.id => ['runner'], the_king.id => ['corp']
                                                           },
                                                           points: 6),
          cranked.id => PairingStrategies::PlainPlayer.new(cranked.id, cranked.name, true, false,
                                                           opponents: {
                                                             the_king.id => ['corp'], plural.id => ['runner']
                                                           },
                                                           points: 3),
          orbital.id => PairingStrategies::PlainPlayer.new(orbital.id, orbital.name, true, false,
                                                           opponents: { gorphax.id => ['corp'] }, points: 3,
                                                           side_bias: 1, had_bye: true),
          the_king.id => PairingStrategies::PlainPlayer.new(the_king.id, the_king.name, true, false,
                                                            opponents: {
                                                              cranked.id => ['runner'], gorphax.id => ['runner']
                                                            },
                                                            side_bias: -2, points: 3)
        }
      )
    end
  end
end
