# frozen_string_literal: true

RSpec.describe RoundsController do
  describe 'pairings data' do
    let(:organiser) { create(:user) }
    let(:tournament) { create(:tournament, name: 'My Tournament', user: organiser) }
    let!(:alice) { create(:player, tournament:, name: 'Alice', pronouns: 'she/her') }
    let!(:bob) { create(:player, tournament:, name: 'Bob', pronouns: 'he/him') }
    let!(:charlie) { create(:player, tournament:, name: 'Charlie', pronouns: 'she/her') }

    describe 'during player meeting' do
      it 'displays without logging in' do
        sign_in nil
        get pairings_data_tournament_rounds_path(tournament)

        expect(compare_body(response))
          .to eq(
            'is_player_meeting' => true,
            'policy' => { 'update' => false },
            'stages' => [swiss_stage_with_rounds([])]
          )
      end

      it 'displays as player' do
        sign_in alice
        get pairings_data_tournament_rounds_path(tournament)

        expect(compare_body(response))
          .to eq(
            'is_player_meeting' => true,
            'policy' => { 'update' => false },
            'stages' => [swiss_stage_with_rounds([])]
          )
      end

      it 'displays as organiser' do
        sign_in organiser
        get pairings_data_tournament_rounds_path(tournament)

        expect(compare_body(response))
          .to eq(
            'is_player_meeting' => true,
            'policy' => { 'update' => true },
            'stages' => [swiss_stage_with_rounds([])]
          )
      end
    end

    describe 'during first swiss round before any results' do
      before do
        Pairer.new(tournament.new_round!, Random.new(0)).pair!
      end

      it 'displays without logging in' do
        sign_in nil
        get pairings_data_tournament_rounds_path(tournament)
        expect(compare_body(response))
          .to eq({
                   'is_player_meeting' => false,
                   'policy' => { 'update' => false },
                   'stages' => [swiss_stage_with_rounds(
                     [
                       {
                         'number' => 1,
                         'pairings' => [
                           { 'intentional_draw' => false,
                             'player1' => player_with_no_ids('Charlie (she/her)'),
                             'player2' => player_with_no_ids('Bob (he/him)'),
                             'policy' => { 'view_decks' => false, 'self_report' => false },
                             'ui_metadata' => { 'row_highlighted' => false },
                             'score_label' => ' - ', 'two_for_one' => false,
                             'table_label' => 'Table 1', 'table_number' => 1, 'self_report' => nil,
                             'round' => nil, 'successor_game' => nil, 'bracket_type' => nil },
                           { 'intentional_draw' => false,
                             'player1' => player_with_no_ids('Alice (she/her)'),
                             'player2' => bye_player,
                             'policy' => { 'view_decks' => false, 'self_report' => false },
                             'ui_metadata' => { 'row_highlighted' => false },
                             'score_label' => '6 - 0', 'two_for_one' => false,
                             'table_label' => 'Table 2', 'table_number' => 2, 'self_report' => nil,
                             'round' => nil, 'successor_game' => nil, 'bracket_type' => nil }
                         ], 'pairings_reported' => 1
                       }
                     ]
                   )]
                 })
      end

      it 'displays as organiser' do
        sign_in organiser
        get pairings_data_tournament_rounds_path(tournament)
        expect(compare_body(response))
          .to eq({
                   'is_player_meeting' => false,
                   'policy' => { 'update' => true },
                   'stages' => [swiss_stage_with_rounds(
                     [
                       {
                         'number' => 1,
                         'pairings' => [
                           { 'intentional_draw' => false,
                             'player1' => player_with_no_ids('Charlie (she/her)'),
                             'player2' => player_with_no_ids('Bob (he/him)'),
                             'policy' => {
                               'view_decks' => false,
                               'self_report' => false
                             }, # sees player view as a player
                             'ui_metadata' => { 'row_highlighted' => false },
                             'score_label' => ' - ', 'two_for_one' => false,
                             'table_label' => 'Table 1', 'table_number' => 1, 'self_report' => nil,
                             'round' => nil, 'successor_game' => nil, 'bracket_type' => nil },
                           { 'intentional_draw' => false,
                             'player1' => player_with_no_ids('Alice (she/her)'),
                             'player2' => bye_player,
                             'policy' => {
                               'view_decks' => false,
                               'self_report' => false
                             }, # sees player view as a player
                             'ui_metadata' => { 'row_highlighted' => false },
                             'score_label' => '6 - 0', 'two_for_one' => false,
                             'table_label' => 'Table 2', 'table_number' => 2, 'self_report' => nil,
                             'round' => nil, 'successor_game' => nil, 'bracket_type' => nil }
                         ], 'pairings_reported' => 1
                       }
                     ]
                   )]
                 })
      end
    end

    describe 'during cut before any results' do
      before do
        Pairer.new(tournament.new_round!, Random.new(0)).pair!
        tournament.cut_to!(:double_elim, 3)
        Pairer.new(tournament.new_round!, Random.new(0)).pair!
      end

      it 'displays without logging in' do
        sign_in nil
        get pairings_data_tournament_rounds_path(tournament)
        expect(compare_body(response))
          .to eq({
                   'is_player_meeting' => false,
                   'policy' => { 'update' => false },
                   'stages' => [
                     swiss_stage_with_rounds(
                       [
                         {
                           'number' => 1,
                           'pairings' => [
                             { 'intentional_draw' => false,
                               'player1' => player_with_no_ids('Charlie (she/her)'),
                               'player2' => player_with_no_ids('Bob (he/him)'),
                               'policy' => { 'view_decks' => false, 'self_report' => false },
                               'ui_metadata' => { 'row_highlighted' => false },
                               'score_label' => ' - ', 'two_for_one' => false,
                               'table_label' => 'Table 1', 'table_number' => 1, 'self_report' => nil,
                               'round' => nil, 'successor_game' => nil, 'bracket_type' => nil },
                             { 'intentional_draw' => false,
                               'player1' => player_with_no_ids('Alice (she/her)'),
                               'player2' => bye_player,
                               'policy' => { 'view_decks' => false, 'self_report' => false },
                               'ui_metadata' => { 'row_highlighted' => false },
                               'score_label' => '6 - 0', 'two_for_one' => false,
                               'table_label' => 'Table 2', 'table_number' => 2, 'self_report' => nil,
                               'round' => nil, 'successor_game' => nil, 'bracket_type' => nil }
                           ], 'pairings_reported' => 1
                         }
                       ]
                     ),
                     cut_stage_with_rounds(
                       [
                         {
                           'number' => 1,
                           'pairings' => [
                             { 'intentional_draw' => false,
                               'player1' => player_with_no_ids('Bob (he/him)'),
                               'player2' => player_with_no_ids('Charlie (she/her)'),
                               'policy' => { 'view_decks' => false, 'self_report' => false },
                               'ui_metadata' => { 'row_highlighted' => false },
                               'score_label' => ' - ', 'two_for_one' => false,
                               'table_label' => 'Game 1', 'table_number' => 1, 'self_report' => nil,
                               'round' => 1, 'successor_game' => 2, 'bracket_type' => 'upper' }
                           ],
                           'pairings_reported' => 0
                         },
                         {
                           'number' => 2,
                           'pairings' => [
                             { 'table_number' => 2, 'round' => 2, 'successor_game' => nil,
                               'bracket_type' => 'upper' }
                           ]
                         }
                       ]
                     )
                   ]
                 })
      end
    end

    describe 'during single sided swiss after first round results' do
      before do
        tournament.update(swiss_format: :single_sided)
        Pairer.new(tournament.new_round!, Random.new(0)).pair!
        pairings = tournament.stages.last.rounds.last.pairings
        pairings.first.update(side: :player1_is_corp,
                              score1: 3, score1_corp: 3, score1_runner: 0,
                              score2: 0, score2_corp: 0, score2_runner: 0)
      end

      it 'displays without logging in' do
        sign_in nil
        get pairings_data_tournament_rounds_path(tournament)
        expect(compare_body(response))
          .to eq({
                   'is_player_meeting' => false,
                   'policy' => { 'update' => false },
                   'stages' => [swiss_stage_with_rounds(
                     [
                       {
                         'number' => 1,
                         'pairings' => [
                           { 'intentional_draw' => false,
                             'player1' => player_with_no_ids('Charlie (she/her)', side: 'corp', side_label: '(Corp)'),
                             'player2' => player_with_no_ids('Bob (he/him)', side: 'runner', side_label: '(Runner)'),
                             'policy' => { 'view_decks' => false, 'self_report' => false },
                             'ui_metadata' => { 'row_highlighted' => false },
                             'score_label' => '3 - 0 (C)', 'two_for_one' => false,
                             'table_label' => 'Table 1', 'table_number' => 1, 'self_report' => nil,
                             'round' => nil, 'successor_game' => nil, 'bracket_type' => nil },
                           { 'intentional_draw' => false,
                             'player1' => player_with_no_ids('Alice (she/her)'),
                             'player2' => bye_player,
                             'policy' => { 'view_decks' => false, 'self_report' => false },
                             'ui_metadata' => { 'row_highlighted' => false },
                             'score_label' => '6 - 0', 'two_for_one' => false,
                             'table_label' => 'Table 2', 'table_number' => 2, 'self_report' => nil,
                             'round' => nil, 'successor_game' => nil, 'bracket_type' => nil }
                         ], 'pairings_reported' => 2
                       }
                     ]
                   )]
                 })
      end
    end

    describe 'during single sided swiss after first round results - player1 is runner' do
      before do
        tournament.update(swiss_format: :single_sided)
        Pairer.new(tournament.new_round!, Random.new(0)).pair!
        pairings = tournament.stages.last.rounds.last.pairings
        pairings.first.update(side: :player1_is_runner,
                              score1: 3, score1_corp: 0, score1_runner: 3,
                              score2: 0, score2_corp: 0, score2_runner: 0)
      end

      it 'displays player 1 score on the right (runner) side' do
        sign_in nil
        get pairings_data_tournament_rounds_path(tournament)
        expect(compare_body(response))
          .to eq({
                   'is_player_meeting' => false,
                   'policy' => { 'update' => false },
                   'stages' => [swiss_stage_with_rounds(
                     [
                       {
                         'number' => 1,
                         'pairings' => [
                           { 'intentional_draw' => false,
                             'player1' => player_with_no_ids(
                               'Charlie (she/her)', side: 'runner', side_label: '(Runner)'
                             ),
                             'player2' => player_with_no_ids('Bob (he/him)', side: 'corp', side_label: '(Corp)'),
                             'policy' => { 'view_decks' => false, 'self_report' => false },
                             'ui_metadata' => { 'row_highlighted' => false },
                             'score_label' => '0 - 3 (R)', 'two_for_one' => false,
                             'table_label' => 'Table 1', 'table_number' => 1, 'self_report' => nil,
                             'round' => nil, 'successor_game' => nil, 'bracket_type' => nil },
                           { 'intentional_draw' => false,
                             'player1' => player_with_no_ids('Alice (she/her)'),
                             'player2' => bye_player,
                             'policy' => { 'view_decks' => false, 'self_report' => false },
                             'ui_metadata' => { 'row_highlighted' => false },
                             'score_label' => '6 - 0', 'two_for_one' => false,
                             'table_label' => 'Table 2', 'table_number' => 2, 'self_report' => nil,
                             'round' => nil, 'successor_game' => nil, 'bracket_type' => nil }
                         ], 'pairings_reported' => 2
                       }
                     ]
                   )]
                 })
      end
    end
  end

  def compare_body(response)
    body = JSON.parse(response.body)
    body['stages'].each do |stage|
      stage.delete 'id'
      stage['rounds'].each do |round|
        round.delete 'id'
        round['pairings'].each do |pairing|
          pairing.delete 'id'
          pairing['player1']&.delete 'id'
          pairing['player2']&.delete 'id'
        end
      end
    end
    body
  end

  def player_with_no_ids(name_with_pronouns, side: nil, side_label: nil)
    {
      'name_with_pronouns' => name_with_pronouns,
      'user_id' => nil,
      'corp_id' => { 'faction' => nil, 'name' => nil },
      'runner_id' => { 'faction' => nil, 'name' => nil },
      'side' => side,
      'side_label' => side_label
    }
  end

  def bye_player
    { 'corp_id' => nil, 'name_with_pronouns' => '(Bye)', 'runner_id' => nil, 'side' => nil, 'side_label' => nil,
      'user_id' => nil }
  end

  def swiss_stage_with_rounds(rounds)
    {
      'name' => 'Swiss',
      'format' => 'swiss',
      'is_single_sided' => false,
      'is_elimination' => false,
      'rounds' => rounds
    }
  end

  def cut_stage_with_rounds(rounds)
    {
      'name' => 'Double Elim',
      'format' => 'double_elim',
      'is_single_sided' => true,
      'is_elimination' => true,
      'rounds' => rounds
    }
  end
end
