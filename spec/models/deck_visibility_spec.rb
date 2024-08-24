# frozen_string_literal: true

RSpec.describe 'deck visibility' do
  let(:tournament) { create(:tournament) }
  let(:unregistered_user) { create(:user) }

  let(:jack) { create(:player, tournament:, user: create(:user)) }
  let(:jill) { create(:player, tournament:) }
  let(:alice) { create(:player, tournament:, user: create(:user)) }
  let(:bob) { create(:player, tournament:) }
  let(:bubble_boy) { create(:player, tournament:, user: create(:user)) }

  let(:swiss) { tournament.stages.find_by!(format: :swiss) }
  let(:cut) { create(:stage, tournament:, format: :double_elim) }

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

  describe 'view decks of players' do
    describe 'private lists' do
      it 'does not show decks of your opponent' do
        expect(jill.decks_visible_to(jack.user)).to be(false)
      end

      it 'does not show your own deck as visible' do
        expect(jack.decks_visible_to(jack.user)).to be(false)
      end
    end

    describe 'open lists' do
      before { tournament.update(cut_deck_visibility: :cut_decks_open) }

      it 'shows decks of your opponent' do
        expect(jill.decks_visible_to(jack.user)).to be(true)
      end

      it 'shows decks of a player in another cut pairing' do
        expect(jill.decks_visible_to(alice.user)).to be(true)
      end

      it 'shows your own deck is visible' do
        expect(jack.decks_visible_to(jack.user)).to be(true)
      end

      it 'shows decks of a cut player to the TO' do
        expect(jack.decks_visible_to(tournament.user)).to be(true)
      end

      it 'does not show decks to a player not in the cut' do
        expect(jill.decks_visible_to(bubble_boy.user)).to be(false)
      end

      it 'does not show decks of a player not in the cut' do
        expect(bubble_boy.decks_visible_to(jill.user)).to be(false)
      end

      it 'does not show decks to the TO when player is not in the cut' do
        expect(bubble_boy.decks_visible_to(tournament.user)).to be(false)
      end
    end

    describe 'public lists' do
      before { tournament.update(cut_deck_visibility: :cut_decks_public) }

      it 'shows decks of your opponent' do
        expect(jill.decks_visible_to(jack.user)).to be(true)
      end

      it 'shows decks of a player in another cut pairing' do
        expect(jill.decks_visible_to(alice.user)).to be(true)
      end

      it 'shows your own deck is visible' do
        expect(jack.decks_visible_to(jack.user)).to be(true)
      end

      it 'shows decks of a cut player to the TO' do
        expect(jack.decks_visible_to(tournament.user)).to be(true)
      end

      it 'shows decks to a player not in the cut' do
        expect(jill.decks_visible_to(bubble_boy.user)).to be(true)
      end

      it 'shows decks to an unauthenticated user' do
        expect(jill.decks_visible_to(nil)).to be(true)
      end

      it 'does not show decks of a player not in the cut' do
        expect(bubble_boy.decks_visible_to(jill.user)).to be(false)
      end

      it 'does not show decks of a player not in the cut to the TO' do
        expect(bubble_boy.decks_visible_to(tournament.user)).to be(false)
      end
    end

    describe 'open list swiss' do
      before { tournament.update(swiss_deck_visibility: :swiss_decks_open) }

      it 'shows decks of a player in swiss to another player in swiss' do
        expect(jack.decks_visible_to(alice.user)).to be(true)
      end

      it 'does not show decks of a player in swiss to an unauthenticated user' do
        expect(jack.decks_visible_to(nil)).to be(false)
      end
    end

    describe 'public list swiss' do
      before { tournament.update(swiss_deck_visibility: :swiss_decks_public) }

      it 'shows decks of a player in swiss to another player in swiss' do
        expect(jack.decks_visible_to(alice.user)).to be(true)
      end

      it 'shows decks of a player in swiss to an unauthenticated user' do
        expect(jack.decks_visible_to(nil)).to be(true)
      end
    end
  end

  context 'a pairing in the cut' do
    let(:pairing) do
      create(:pairing, :player1_is_corp,
             round: create(:round, stage: cut),
             player1: jack, player2: jill)
    end

    describe 'private lists' do
      it 'does not let you see decks in your pairing' do
        expect(pairing.decks_visible_to(jack.user)).to be(false)
      end

      it 'does not let you see decks in a pairing of other players' do
        expect(pairing.decks_visible_to(alice.user)).to be(false)
      end

      it 'does not let you see decks when not in cut' do
        expect(pairing.decks_visible_to(bubble_boy.user)).to be(false)
      end

      it 'does not let you see decks when unregistered' do
        expect(pairing.decks_visible_to(unregistered_user)).to be(false)
      end

      it 'does not let you see decks when unauthenticated' do
        expect(pairing.decks_visible_to(nil)).to be(false)
      end

      it 'forces the TO to use the players tab to see decks' do
        expect(pairing.decks_visible_to(tournament.user)).to be(false)
      end
    end

    describe 'open list cut' do
      before { tournament.update(cut_deck_visibility: :cut_decks_open) }

      it 'allows you to see decks in your pairing' do
        expect(pairing.decks_visible_to(jack.user)).to be(true)
      end

      it 'allows you to see decks in a pairing of other players' do
        expect(pairing.decks_visible_to(alice.user)).to be(true)
      end

      it 'does not let you see decks when not in cut' do
        expect(pairing.decks_visible_to(bubble_boy.user)).to be(false)
      end

      it 'does not let you see decks when unregistered' do
        expect(pairing.decks_visible_to(unregistered_user)).to be(false)
      end

      it 'does not let you see decks when unauthenticated' do
        expect(pairing.decks_visible_to(nil)).to be(false)
      end

      it 'allows the TO to see decks' do
        expect(pairing.decks_visible_to(tournament.user)).to be(true)
      end
    end

    describe 'public list cut' do
      before { tournament.update(cut_deck_visibility: :cut_decks_public) }

      it 'allows you to see decks in your pairing' do
        expect(pairing.decks_visible_to(jack.user)).to be(true)
      end

      it 'allows you to see decks in a pairing of other players' do
        expect(pairing.decks_visible_to(alice.user)).to be(true)
      end

      it 'allows you to see decks when not in cut' do
        expect(pairing.decks_visible_to(bubble_boy.user)).to be(true)
      end

      it 'allows you to see decks when unregistered' do
        expect(pairing.decks_visible_to(unregistered_user)).to be(true)
      end

      it 'allows you to see decks when unauthenticated' do
        expect(pairing.decks_visible_to(nil)).to be(true)
      end

      it 'allows the TO to see decks' do
        expect(pairing.decks_visible_to(tournament.user)).to be(true)
      end
    end
  end

  context 'a pairing in swiss' do
    let(:pairing) do
      create(:pairing, :player1_is_corp,
             round: create(:round, stage: swiss),
             player1: jack, player2: jill)
    end

    describe 'public list cut' do
      before { tournament.update(cut_deck_visibility: :cut_decks_public) }

      it 'does not let you see decks in your pairing' do
        expect(pairing.decks_visible_to(jack.user)).to be(false)
      end
    end

    describe 'open list swiss' do
      it 'does not show decks for a pairing as 4 decks is too many for one screen' do
        expect(pairing.decks_visible_to(jack.user)).to be(false)
      end
    end
  end

  context 'a pairing with sides not chosen yet' do
    let(:pairing) do
      create(:pairing,
             round: create(:round, stage: cut),
             player1: jack, player2: jill)
    end

    describe 'public list cut' do
      before { tournament.update(cut_deck_visibility: :cut_decks_public) }

      it 'does not show decks as they have not been set for the pairing' do
        expect(pairing.decks_visible_to(jack.user)).to be(false)
      end
    end
  end
end
