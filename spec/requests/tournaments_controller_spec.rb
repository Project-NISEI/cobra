# frozen_string_literal: true

RSpec.describe TournamentsController do
  let(:tournament) { create(:tournament, name: 'My Tournament') }

  let(:btl) { create(:identity, name: 'Builder of Nations', faction: 'weyland-consortium') }
  let(:hoshiko) { create(:identity, name: 'Hoshiko', faction: 'anarch') }
  let(:sable) { create(:identity, name: 'Sable', faction: 'criminal') }
  let(:az) { create(:identity, name: 'Az', faction: 'criminal') }

  let(:player1) do
    create(:player, tournament:, corp_identity: btl.name, corp_identity_ref_id: btl.id, runner_identity: hoshiko.name,
                    runner_identity_ref_id: hoshiko.id)
  end
  let(:player2) do
    create(:player, tournament:, runner_identity: sable.name,
                    runner_identity_ref_id: sable.id)
  end
  let(:player3) do
    create(:player, tournament:, corp_identity: btl.name, corp_identity_ref_id: btl.id, runner_identity: az.name,
                    runner_identity_ref_id: az.id)
  end
  let(:player4) { create(:player, tournament:, corp_identity: btl.name, corp_identity_ref_id: btl.id) }

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

  describe '#id_and_faction_data' do
    it 'returns correct id_and_faction_data JSON' do
      player1.save
      player2.save
      player3.save
      player4.save

      get id_and_faction_data_tournament_path(tournament)

      expect(JSON.parse(response.body))
        .to eq(
          'num_players' => 4,
          'corp' => {
            'factions' => {
              'weyland-consortium' => 3,
              'unspecified' => 1
            },
            'ids' => {
              'Builder of Nations' => { 'count' => 3, 'faction' => 'weyland-consortium' },
              'Unspecified' => { 'count' => 1, 'faction' => 'unspecified' }
            }
          },
          'runner' => {
            'factions' => {
              'unspecified' => 1,
              'anarch' => 1,
              'criminal' => 2
            },
            'ids' => {
              'Az' => { 'count' => 1, 'faction' => 'criminal' },
              'Hoshiko' => { 'count' => 1, 'faction' => 'anarch' },
              'Sable' => { 'count' => 1, 'faction' => 'criminal' },
              'Unspecified' => { 'count' => 1, 'faction' => 'unspecified' }
            }
          },
          'cut' => {
            'num_players' => 0,
            'corp' => { 'factions' => {}, 'ids' => {} },
            'runner' => { 'factions' => {}, 'ids' => {} }
          }
        )
    end
  end

  describe '#cut_conversion_rates' do
    before do
      allow(Tournament).to receive(:find)
        .with(tournament.to_param)
        .and_return(tournament)
      allow(tournament).to receive(:cut_conversion_rates_data)
        .and_return([{ foo: 'bar' }, { baz: 'qux' }])
    end

    # This method just returns what tournament gives it as JSON.
    it 'returns tournament.side_win_percentages JSON' do
      get cut_conversion_rates_tournament_path(tournament)

      expect(JSON.parse(response.body))
        .to eq([{ 'foo' => 'bar' }, { 'baz' => 'qux' }])
    end
  end

  describe '#side_win_percentages' do
    before do
      allow(Tournament).to receive(:find)
        .with(tournament.to_param)
        .and_return(tournament)
      allow(tournament).to receive(:side_win_percentages_data)
        .and_return([{ foo: 'bar' }, { baz: 'qux' }])
    end

    # This method just returns what tournament gives it as JSON.
    it 'returns tournament.side_win_percentages JSON' do
      get side_win_percentages_tournament_path(tournament)

      expect(JSON.parse(response.body))
        .to eq([{ 'foo' => 'bar' }, { 'baz' => 'qux' }])
    end
  end
end
