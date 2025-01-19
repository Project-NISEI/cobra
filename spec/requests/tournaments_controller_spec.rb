# frozen_string_literal: true

RSpec.describe TournamentsController do
  let(:tournament) { create(:tournament, name: 'My Tournament') }
  let(:player1) { create(:player, tournament:) }
  let(:player2) { create(:player, tournament:) }
  let(:player3) { create(:player, tournament:) }
  let(:player4) { create(:player, tournament:) }

  describe '#save_json' do
    before do
      allow(NrtmJson).to receive(:new).with(tournament).and_return(
        instance_double(NrtmJson, data: { some: :data })
      )
    end

    it 'responds with json file' do
      get save_json_tournament_path(tournament)

      expect(response.headers['Content-Disposition']).to eq(
        'attachment; filename="my tournament.json"; filename*=UTF-8\'\'my%20tournament.json'
      )
      expect(response.body).to eq('{"some":"data"}')
    end
  end

  describe '#cut' do
    let(:cut) { create(:stage, tournament:) }

    before do
      allow(Tournament).to receive(:find)
        .with(tournament.to_param)
        .and_return(tournament)
      allow(tournament).to receive(:cut_to!).and_return(cut)
    end

    it 'cuts tournament' do
      sign_in tournament.user
      post cut_tournament_path(tournament), params: { number: 8 }

      expect(tournament).to have_received(:cut_to!).with(:double_elim, 8)
    end
  end

  describe '#change_swiss_format' do
    before do
      allow(Tournament).to receive(:find)
        .with(tournament.to_param)
        .and_return(tournament)
    end

    it 'changes swiss format when stage has no pairings' do
      sign_in tournament.user

      patch tournament_path(tournament), params: { tournament: { swiss_format: 'single_sided' } }

      expect(tournament.single_sided?).to be(true)
    end

    it 'will not change swiss format when stage has pairings' do
      expect(tournament.swiss?).to be(true)
      tournament.pair_new_round!
      sign_in tournament.user

      patch tournament_path(tournament), params: { tournament: { swiss_format: 'single_sided' } }

      expect(flash[:alert]).to eq("Can't change Swiss format when rounds exist.")

      # Format is unchanged
      expect(tournament.swiss?).to be(true)
    end
  end
end
