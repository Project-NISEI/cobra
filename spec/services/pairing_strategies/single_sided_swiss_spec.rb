# frozen_string_literal: true

RSpec.describe PairingStrategies::SingleSidedSwiss do
  let(:pairer) { described_class.new(round) }
  let(:round) { create(:round, number: 1, tournament:, stage:) }
  let(:stage) { tournament.current_stage }
  let(:tournament) { create(:tournament, swiss_format: :single_sided) }
  let(:nil_player) { NilPlayer.new }

  before do
    allow(NilPlayer).to receive(:new).and_return(nil_player)
  end

  describe '.points_weight' do
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }

    context 'with no games played' do
      it 'returns 0' do
        expect(described_class.points_weight(player1.points, player2.points)).to eq(0)
      end
    end

    context 'with a point difference' do
      before do
        create(:pairing, player1:, score1: 3, score2: 0)
      end

      it 'returns a negative number' do
        expect(described_class.points_weight(player1.points, player2.points)).to eq(-1.5)
      end
    end

    context 'with a larger point difference' do
      before do
        create(:pairing, player1:, score1: 3, score2: 0)
        create(:pairing, player1:, score1: 3, score2: 0)
        create(:pairing, player1:, score1: 0, score2: 3)
      end

      it 'returns a more negative number' do
        expect(described_class.points_weight(player1.points, player2.points)).to eq(-6)
      end
    end

    context 'with a tied points value' do
      before do
        create(:pairing, player1:, score1: 3, score2: 0)
        create(:pairing, player1: player2, score1: 3, score2: 0)
      end

      it 'returns 0' do
        expect(described_class.points_weight(player1.points, player2.points)).to eq(0)
      end
    end
  end

  describe '.side_bias_weight' do
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }

    context 'with no games played' do
      it 'returns 0' do
        expect(described_class.side_bias_weight(player1.side_bias, player2.side_bias)).to eq(1)
      end
    end

    context 'with same bias' do
      before do
        create(:pairing, player1:, side: :player1_is_corp)
        create(:pairing, player1: player2, side: :player1_is_corp)
      end

      it 'returns 0' do
        expect(described_class.side_bias_weight(player1.side_bias, player2.side_bias)).to eq(1)
      end
    end

    context 'with opposite bias' do
      before do
        create(:pairing, player1:, side: :player1_is_corp)
        create(:pairing, player1: player2, side: :player1_is_runner)
      end

      it 'returns positive number' do
        expect(described_class.side_bias_weight(player1.side_bias, player2.side_bias)).to eq(8)
      end
    end

    context 'with even more opposite bias' do
      before do
        create(:pairing, player1:, side: :player1_is_corp)
        create(:pairing, player1:, side: :player1_is_corp)

        create(:pairing, player1: player2, side: :player1_is_runner)
        create(:pairing, player1: player2, side: :player1_is_runner)
      end

      it 'returns more positive number' do
        expect(described_class.side_bias_weight(player1.side_bias, player2.side_bias)).to eq(64)
      end
    end
  end

  describe '.rematch_bias_weight' do
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }

    it 'returns 0 with no games played' do
      expect(described_class.rematch_bias_weight(false)).to eq(0)
    end

    it 'returns small negative number with 1 game played' do
      expect(described_class.rematch_bias_weight(true)).to eq(-0.5)
    end
  end

  describe '.preferred_player1_side' do
    let(:player1) { create(:player) }
    let(:player2) { create(:player) }

    it 'returns nil with no data' do
      expect(described_class.preferred_player1_side(player1.side_bias, player2.side_bias)).to be_nil
    end

    context 'when player 1 has corped many times' do
      before do
        create(:pairing, player1:, side: :player1_is_corp)
        create(:pairing, player1:, side: :player1_is_corp)
        create(:pairing, player1:, side: :player1_is_corp)
      end

      it 'returns :runner' do
        expect(described_class.preferred_player1_side(player1.side_bias, player2.side_bias)).to eq(:runner)
      end

      context 'and player 2 has corped once' do
        before do
          create(:pairing, player2:, side: :player1_is_runner)
        end

        it 'returns :runner' do
          expect(described_class.preferred_player1_side(player1.side_bias, player2.side_bias)).to eq(:runner)
        end
      end

      context 'and player 2 has corped even more times' do
        before do
          create(:pairing, player2:, side: :player1_is_runner)
          create(:pairing, player2:, side: :player1_is_runner)
          create(:pairing, player2:, side: :player1_is_runner)
          create(:pairing, player2:, side: :player1_is_runner)
        end

        it 'returns :corp' do
          expect(described_class.preferred_player1_side(player1.side_bias, player2.side_bias)).to eq(:corp)
        end
      end

      context 'and player 2 has corped the same amount' do
        before do
          create(:pairing, player2:, side: :player1_is_runner)
          create(:pairing, player2:, side: :player1_is_runner)
          create(:pairing, player2:, side: :player1_is_runner)
        end

        it 'returns nil' do
          expect(described_class.preferred_player1_side(player1.side_bias, player2.side_bias)).to be_nil
        end
      end
    end
  end

  describe '#pair!' do
    context 'with four players' do
      %i[jack jill hansel gretel].each do |name|
        let!(name) do
          create(:player, name: name.to_s.humanize, tournament:)
        end
      end

      it 'returns pairings for all players' do
        pairer.pair!

        round.reload
        expect(round.pairings.count).to eq(2)
        expect(round.pairings.map(&:players).flatten).to contain_exactly(jack, jill, hansel, gretel)
      end

      it 'assigns sides' do
        pairer.pair!

        round.reload
        expect(round.pairings.map(&:side).compact.count).to eq(2)
      end

      context 'when in second round' do
        let(:round1) { create(:round, stage:, number: 1, completed: true) }
        let(:round2) { create(:round, stage:, number: 2) }
        let(:pairer) { described_class.new(round2) }

        before do
          create(:pairing, round: round1,
                           player1: jack, player2: jill,
                           score1: 3, score2: 0,
                           side: :player1_is_corp)
          create(:pairing, round: round1,
                           player1: hansel, player2: gretel,
                           score1: 3, score2: 0,
                           side: :player1_is_runner)
        end

        it 'pairs based on points' do
          pairer.pair!

          round2.reload
          round2.pairings.each do |pairing|
            expect(pairing.players).to contain_exactly(jack, hansel) if pairing.players.include? jack
            expect(pairing.players).to contain_exactly(jill, gretel) if pairing.players.include? jill
          end
        end

        it 'assigns sides' do
          pairer.pair!

          round2.reload
          round2.pairings.each do |pairing|
            expect(pairing.side_for(jack)).to eq(:runner) if pairing.players.include? jack
            expect(pairing.side_for(jill)).to eq(:corp) if pairing.players.include? jill
          end
        end

        it 'allows repeat matchups' do
          create(:pairing, player1: jack, player2: hansel)

          pairer.pair!

          round2.reload
          round2.pairings.each do |pairing|
            expect(pairing.players).to contain_exactly(jack, hansel) if pairing.players.include? jack
            expect(pairing.players).to contain_exactly(jill, gretel) if pairing.players.include? jill
          end
        end

        it 'avoids third matchups' do
          create(:pairing, player1: jack, player2: hansel)
          create(:pairing, player1: jack, player2: hansel)

          pairer.pair!

          round2.reload
          round2.pairings.each do |pairing|
            expect(pairing.players).not_to include(hansel) if pairing.players.include? jack
          end
        end

        context 'when side bias is bad for repeat matchup' do
          before do
            create(:pairing, player1: jack, side: :player1_is_corp)
            create(:pairing, player1: hansel, side: :player1_is_runner)
            create(:pairing, player1: jack, player2: hansel, side: :player1_is_runner)
          end

          it 'avoids repeat matchups' do
            pairer.pair!

            round2.reload
            round2.pairings.each do |pairing|
              expect(pairing.players).not_to include(hansel) if pairing.players.include? jack
            end
          end
        end
      end
    end

    context 'with three players' do
      %i[snap crackle pop].each do |name|
        let!(name) do
          create(:player, name: name.to_s.humanize, tournament:)
        end
      end

      it 'creates bye' do
        pairer.pair!

        round.reload
        expect(round.pairings.count).to eq(2)
        expect(round.pairings.map(&:players).flatten).to contain_exactly(snap, crackle, pop, nil_player)
        # Byes for Single-sided swiss are only worth 3 points.
        round.pairings.each do |pairing|
          if pairing.players.include? nil_player
            if pairing.player1_id.nil?
              expect(pairing.score2).to eq(3)
            else
              expect(pairing.score1).to eq(3)
            end
          end
        end
      end

      it 'assigns sides' do
        pairer.pair!

        round.reload
        expect(round.pairings.bye.first.side).to be_nil
        expect(round.pairings.non_bye.first.side).not_to be_nil
      end

      context 'when in second round' do
        let(:round1) { create(:round, tournament:, stage:, number: 1, completed: true) }
        let(:round2) { create(:round, tournament:, stage:, number: 2) }
        let(:pairer) { described_class.new(round2) }

        before do
          create(:pairing, round: round1,
                           player1: snap, player2: crackle,
                           score1: 3, score2: 0,
                           side: :player1_is_corp)
          create(:pairing, round: round1,
                           player1: pop, player2: nil,
                           score1: 3, score2: 0,
                           side: nil)
        end

        it 'pairs based on points' do
          pairer.pair!

          round2.reload
          expect(round2.pairings.count).to eq(2)
          round2.pairings.each do |pairing|
            expect(pairing.players).to contain_exactly(snap, pop) if pairing.players.include? snap
            expect(pairing.players).to contain_exactly(crackle, nil_player) if pairing.players.include? crackle
          end
        end

        it 'assigns sides' do
          pairer.pair!

          round2.reload
          round2.pairings.each do |pairing|
            expect(pairing.side_for(snap)).to eq(:runner) if pairing.players.include? snap
            expect(pairing.side_for(crackle)).to be_nil if pairing.players.include? crackle
          end
        end

        it 'allows repeat matchups' do
          create(:pairing, player1: snap, player2: pop)

          pairer.pair!

          round2.reload
          round2.pairings.each do |pairing|
            expect(pairing.players).to contain_exactly(snap, pop) if pairing.players.include? snap
            expect(pairing.players).to contain_exactly(crackle, nil_player) if pairing.players.include? crackle
          end
        end

        # This shouldn't be in the second round context - it needs at least 2 completed rounds to test.
        # TODO(plural): Move this out.
        it 'avoids third matchups' do
          # Round 1:
          # Snap (R) vs Crackle (C)
          # Pop (Bye)
          round1.pairings.delete_all
          create(:pairing, round: round1, player1: snap, player2: crackle, score1: 0, score2: 3,
                           side: :player1_is_runner)
          create(:pairing, round: round1, player1: pop, player2: nil, score1: 1)

          # Set up Round 2
          round2.completed = true
          round2.save
          create(:pairing, round: round2, player1: snap, player2: crackle, score1: 3, score2: 0,
                           side: :player1_is_corp)
          create(:pairing, round: round2, player1: pop, player2: nil, score1: 1)

          # Artificial Standings
          # Snap    3
          # Crackle 3
          # Pop     2

          round3 = create(:round, tournament:, stage:, number: 3)
          pairer = described_class.new(round3)
          pairer.pair!

          round3.reload
          round3.pairings.each do |pairing|
            expect(pairing.players).not_to include(snap) if pairing.players.include? crackle
          end
        end

        it 'avoids second bye when real pairing was a tie' do
          # Round 1:
          #   Snap (1) vs Crackle (1) - tie so neither player gets the bye only on points.
          #   Pop (bye)
          # Standings
          #   Pop     3 (bye)
          #   Snap    1
          #   Crackle 1
          # Round 2:
          #   Pop (3) vs Crackle|Snap
          #   Crackle|Snap: Bye

          round1.pairings.delete_all
          create(:pairing, round: round1, player1: snap, player2: crackle, score1: 1, score2: 1,
                           side: :player1_is_runner)
          create(:pairing, round: round1, player1: pop, player2: nil, score1: 3)

          pairer.pair!

          round2.pairings.each do |pairing|
            expect(pairing.players).not_to include(pop) if pairing.players.include? nil_player
          end
        end

        it 'avoids second bye really in the third round.' do
          # Round 1:
          #   Snap (3) vs Crackle (0)
          #   Pop (bye)
          # Standings
          #   Snap    3
          #   Pop     3 (bye)
          #   Crackle 0
          # Round 2:
          #   Snap (3) vs Pop (0)
          #   Crackle: Bye
          # Standings
          #   Snap (6)
          #   Pop (3)
          #   Crackle (3)
          # Round 3:
          #   Pop vs Crackle
          #   Snap (Bye)

          # expect(pairing.side_for(snap)).to eq(:runner) if pairing.players.include? snap
          # expect(pairing.side_for(crackle)).to be_nil if pairing.players.include? crackle

          create(:pairing, round: round2, player1: snap, player2: pop, score1: 3, score2: 0, side: :player1_is_runner)
          create(:pairing, round: round2, player1: crackle, player2: nil, score1: 3)

          round2.completed = true
          round2.save

          round3 = create(:round, tournament:, stage:, number: 3)
          pairer = described_class.new(round3)
          pairer.pair!

          round3.pairings.each do |pairing|
            # Real pairing should be pop vs. crackle
            expect(pairing.players).to contain_exactly(crackle, pop) unless pairing.players.include? nil_player
            # Snap will have the bye
            expect(pairing.players).to include(snap) if pairing.players.include? nil_player
          end
        end
      end
    end
  end
end
