RSpec.describe 'pairing deck visibility' do
  let(:tournament) { create(:tournament) }
  let(:unregistered_user) { create(:user) }

  let(:jack) { create(:player, user: create(:user)) }
  let(:jill) { create(:player) }
  let(:alice) { create(:player, user: create(:user)) }
  let(:bob) { create(:player) }
  let(:bubble_boy) { create(:player, user: create(:user)) }

  let(:swiss) { tournament.stages.find_by!(format: :swiss) }
  let(:cut) { create(:stage, tournament: tournament, format: :double_elim) }
  let(:pairing) { create(:pairing, :player1_is_corp,
                         round: create(:round, stage: cut),
                         player1: jack, player2: jill) }

  before do
    create(:registration, player: jack, stage: swiss)
    create(:registration, player: jill, stage: swiss)
    create(:registration, player: alice, stage: swiss)
    create(:registration, player: bob, stage: swiss)
    create(:registration, player: bubble_boy, stage: swiss)
    create(:registration, player: jack, stage: cut)
    create(:registration, player: jill, stage: cut)
    create(:registration, player: alice, stage: cut)
    create(:registration, player: bob, stage: cut)
  end

  describe 'private lists' do
    it 'does not let you see decks in your pairing' do
      expect(pairing.cut_decks_visible_to(jack.user)).to be(false)
    end

    it 'does not let you see decks in a pairing of other players' do
      expect(pairing.cut_decks_visible_to(alice.user)).to be(false)
    end

    it 'does not let you see decks when not in cut' do
      expect(pairing.cut_decks_visible_to(bubble_boy.user)).to be(false)
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

    it 'does not let you see decks when not in cut' do
      expect(pairing.cut_decks_visible_to(bubble_boy.user)).to be(false)
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

    it 'allows you to see decks when not in cut' do
      expect(pairing.cut_decks_visible_to(bubble_boy.user)).to be(true)
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