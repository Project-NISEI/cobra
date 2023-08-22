RSpec.describe 'pairing deck visibility' do
  let(:tournament) { create(:tournament) }
  let(:unregistered_user) { create(:user) }

  let(:jack) { create(:player, user: create(:user)) }
  let(:jill) { create(:player) }
  let(:alice) { create(:player, user: create(:user)) }
  let(:bob) { create(:player) }

  let(:stage) { tournament.cut_to! :double_elim, 4 }
  let(:round) { create(:round, stage: stage) }
  let(:pairing) { create(:pairing, :player1_is_corp, round: round, player1: jack, player2: jill) }

  describe 'private lists' do
    it 'does not let you see decks in your pairing' do
      expect(pairing.cut_decks_visible_to(jack.user)).to be(false)
    end

    it 'does not let you see decks in a pairing of other players' do
      expect(pairing.cut_decks_visible_to(alice.user)).to be(false)
    end

    it 'does not let you see decks when unregistered' do
      expect(pairing.cut_decks_visible_to(unregistered_user)).to be(false)
    end

    it 'does not let you see decks when unauthenticated' do
      expect(pairing.cut_decks_visible_to(nil)).to be(false)
    end

    it 'forces the TO to use the players tab to see decks' do
      expect(pairing.cut_decks_visible_to(tournament.user)).to be(false)
    end
  end

  describe 'open list cut' do
    before { tournament.update(open_list_cut: true) }

    it 'allows you to see decks in your pairing' do
      expect(pairing.cut_decks_visible_to(jack.user)).to be(true)
    end

    it 'allows you to see decks in a pairing of other players' do
      expect(pairing.cut_decks_visible_to(alice.user)).to be(true)
    end

    it 'does not let you see decks when unregistered' do
      expect(pairing.cut_decks_visible_to(unregistered_user)).to be(false)
    end

    it 'does not let you see decks when unauthenticated' do
      expect(pairing.cut_decks_visible_to(nil)).to be(false)
    end

    it 'allows the TO to see decks' do
      expect(pairing.cut_decks_visible_to(tournament.user)).to be(true)
    end
  end

  describe 'public list cut' do
    before { tournament.update(public_list_cut: true) }

    it 'allows you to see decks in your pairing' do
      expect(pairing.cut_decks_visible_to(jack.user)).to be(true)
    end

    it 'allows you to see decks in a pairing of other players' do
      expect(pairing.cut_decks_visible_to(alice.user)).to be(true)
    end

    it 'allows you to see decks when unregistered' do
      expect(pairing.cut_decks_visible_to(unregistered_user)).to be(true)
    end

    it 'allows you to see decks when unauthenticated' do
      expect(pairing.cut_decks_visible_to(nil)).to be(true)
    end

    it 'allows the TO to see decks' do
      expect(pairing.cut_decks_visible_to(tournament.user)).to be(true)
    end
  end
end