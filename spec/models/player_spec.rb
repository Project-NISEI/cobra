# frozen_string_literal: true

RSpec.describe Player do
  let(:player) { create(:player) }

  describe '#pairings' do
    let(:pairing) { create(:pairing) }
    let(:another) { create(:pairing, player2: pairing.player1) }
    let(:unrelated) { create(:pairing) }

    it 'returns correct pairings' do
      expect(pairing.player1.pairings).to eq([pairing, another])
    end
  end

  describe '#non_bye_pairings' do
    let!(:pairing1) { create(:pairing, player1: player) }
    let!(:pairing2) { create(:pairing, player2: player) }
    let!(:bye_pairing) { create(:pairing, player1: player, player2: nil) }

    it 'only returns non-byes' do
      expect(player.non_bye_pairings).to eq([pairing1, pairing2])
    end
  end

  describe 'eligible_pairings' do
    let(:complete) { create(:round, completed: true) }
    let(:incomplete) { create(:round, completed: false) }
    let!(:pairing1) { create(:pairing, round: complete, player1: player) }
    let!(:pairing2) { create(:pairing, round: complete, player1: player) }
    let!(:pairing3) { create(:pairing, round: incomplete, player1: player) }
    let!(:another) { create(:pairing, round: complete) }

    it 'only returns pairings from complete rounds' do
      expect(player.eligible_pairings).to contain_exactly(pairing1, pairing2)
    end
  end

  describe 'dependent pairings' do
    let!(:pairing) { create(:pairing) }

    it 'deletes pairings on delete' do
      expect do
        pairing.player1.destroy
      end.to change(Pairing, :count).by(-1)
    end
  end

  describe 'identities' do
    it 'sets empty identities to nil on update' do
      player.update(runner_identity: '', corp_identity: '')
      expect(player.runner_identity).to be_nil
      expect(player.corp_identity).to be_nil
    end
  end

  describe 'opponents' do
    let!(:pairing1) { create(:pairing, player1: player, score1: 6) }
    let!(:pairing2) { create(:pairing, player1: player, score1: 3) }
    let!(:pairing3) { create(:pairing, player1: player, player2: nil, score1: 6) }

    describe '#opponents' do
      let(:nil_player) { instance_double(NilPlayer) }

      before do
        allow(NilPlayer).to receive(:new).and_return(nil_player)
      end

      it 'returns all opponents' do
        expect(player.opponents).to eq([pairing1.player2, pairing2.player2, nil_player])
      end
    end

    describe '#non_bye_opponents' do
      it 'returns all opponents' do
        expect(player.non_bye_opponents).to eq([pairing1.player2, pairing2.player2])
      end
    end

    describe '#points' do
      it 'returns points earned against all opponents' do
        expect(player.points).to eq(15)
      end
    end

    describe '#sos_earned' do
      it 'returns points earned against non-bye opponents' do
        expect(player.sos_earned).to eq(9)
      end
    end
  end

  describe '#drop!' do
    before do
      player.drop!
    end

    it 'changes player status' do
      expect(player.tournament.players.dropped).to include(player)
    end
  end

  describe '#seed_in_stage' do
    let(:stage1) { create(:stage) }
    let(:stage2) { create(:stage, tournament: stage1.tournament) }
    let(:player) { create(:player, tournament: stage1.tournament, skip_registration: true) }

    before do
      create(:registration, player:, stage: stage1, seed: 123)
      create(:registration, player:, stage: stage2, seed: 456)
    end

    it 'returns the seed for the player in the specified stage' do
      aggregate_failures do
        expect(player.seed_in_stage(stage1)).to eq(123)
        expect(player.seed_in_stage(stage2)).to eq(456)
      end
    end
  end

  describe '#had_bye?' do
    before do
      create_list(:pairing, 3, player1: player)
    end

    context 'when player has not had a bye' do
      it 'returns false' do
        expect(player.had_bye?).to be(false)
      end
    end

    context 'when player has had a bye' do
      before do
        create(:pairing, player1: player, player2: nil)
      end

      it 'returns true' do
        expect(player.had_bye?).to be(true)
      end
    end
  end

  describe '#side_bias' do
    it 'returns 0' do
      expect(player.side_bias).to eq(0)
    end

    context 'with balanced pairings' do
      before do
        create_list(:pairing, 2, player1: player, side: :player1_is_corp)
        create_list(:pairing, 2, player1: player, side: :player1_is_runner)
      end

      it 'returns 0' do
        expect(player.side_bias).to eq(0)
      end
    end

    context 'with more corp pairings' do
      before do
        create_list(:pairing, 3, player1: player, side: :player1_is_corp)
        create_list(:pairing, 1, player1: player, side: :player1_is_runner)
      end

      it 'returns positive number' do
        expect(player.side_bias).to eq(2)
      end
    end

    context 'with more runner pairings' do
      before do
        create_list(:pairing, 1, player1: player, side: :player1_is_corp)
        create_list(:pairing, 4, player1: player, side: :player1_is_runner)
      end

      it 'returns negative number' do
        expect(player.side_bias).to eq(-3)
      end
    end
  end
end
