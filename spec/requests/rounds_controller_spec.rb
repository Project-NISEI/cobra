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
            'stages' => [{ 'name' => 'Swiss', 'format' => 'swiss', 'rounds' => [] }]
          )
      end

      it 'displays as player' do
        sign_in alice
        get pairings_data_tournament_rounds_path(tournament)

        expect(compare_body(response))
          .to eq(
            'is_player_meeting' => true,
            'policy' => { 'update' => false },
            'stages' => [{ 'name' => 'Swiss', 'format' => 'swiss', 'rounds' => [] }]
          )
      end

      it 'displays as organiser' do
        sign_in organiser
        get pairings_data_tournament_rounds_path(tournament)

        expect(compare_body(response))
          .to eq(
            'is_player_meeting' => true,
            'policy' => { 'update' => true },
            'stages' => [{ 'name' => 'Swiss', 'format' => 'swiss', 'rounds' => [] }]
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
                   'stages' => [{ 'name' => 'Swiss', 'format' => 'swiss', 'rounds' => [
                     {
                       'number' => 1,
                       'pairings' => [
                         { 'intentional_draw' => false,
                           'player1' => player_with_no_ids('Charlie (she/her)'),
                           'player2' => player_with_no_ids('Bob (he/him)'),
                           'policy' => { 'view_decks' => false },
                           'score_label' => ' - ', 'two_for_one' => false,
                           'table_label' => 'Table 1', 'table_number' => 1 },
                         { 'intentional_draw' => false,
                           'player1' => player_with_no_ids('Alice (she/her)'),
                           'player2' => bye_player,
                           'policy' => { 'view_decks' => false },
                           'score_label' => '6 - 0', 'two_for_one' => false,
                           'table_label' => 'Table 2', 'table_number' => 2 }
                       ], 'pairings_reported' => 1
                     }
                   ] }]
                 })
      end

      it 'displays as organiser' do
        sign_in organiser
        get pairings_data_tournament_rounds_path(tournament)
        expect(compare_body(response))
          .to eq({
                   'is_player_meeting' => false,
                   'policy' => { 'update' => true },
                   'stages' => [{ 'name' => 'Swiss', 'format' => 'swiss', 'rounds' => [
                     {
                       'number' => 1,
                       'pairings' => [
                         { 'intentional_draw' => false,
                           'player1' => player_with_no_ids('Charlie (she/her)'),
                           'player2' => player_with_no_ids('Bob (he/him)'),
                           'policy' => { 'view_decks' => false }, # sees player view as a player
                           'score_label' => ' - ', 'two_for_one' => false,
                           'table_label' => 'Table 1', 'table_number' => 1 },
                         { 'intentional_draw' => false,
                           'player1' => player_with_no_ids('Alice (she/her)'),
                           'player2' => bye_player,
                           'policy' => { 'view_decks' => false }, # sees player view as a player
                           'score_label' => '6 - 0', 'two_for_one' => false,
                           'table_label' => 'Table 2', 'table_number' => 2 }
                       ], 'pairings_reported' => 1
                     }
                   ] }]
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
                     { 'name' => 'Swiss', 'format' => 'swiss', 'rounds' => [
                       {
                         'number' => 1,
                         'pairings' => [
                           { 'intentional_draw' => false,
                             'player1' => player_with_no_ids('Charlie (she/her)'),
                             'player2' => player_with_no_ids('Bob (he/him)'),
                             'policy' => { 'view_decks' => false },
                             'score_label' => ' - ', 'two_for_one' => false,
                             'table_label' => 'Table 1', 'table_number' => 1 },
                           { 'intentional_draw' => false,
                             'player1' => player_with_no_ids('Alice (she/her)'),
                             'player2' => bye_player,
                             'policy' => { 'view_decks' => false },
                             'score_label' => '6 - 0', 'two_for_one' => false,
                             'table_label' => 'Table 2', 'table_number' => 2 }
                         ], 'pairings_reported' => 1
                       }
                     ] },
                     { 'name' => 'Double Elim', 'format' => 'double_elim', 'rounds' => [
                       {
                         'number' => 1,
                         'pairings' => [
                           { 'intentional_draw' => false,
                             'player1' => player_with_no_ids('Bob (he/him)'),
                             'player2' => player_with_no_ids('Charlie (she/her)'),
                             'policy' => { 'view_decks' => false },
                             'score_label' => ' - ', 'two_for_one' => false,
                             'table_label' => 'Game 1', 'table_number' => 1 }
                         ], 'pairings_reported' => 0
                       }
                     ] }
                   ]
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
        end
      end
    end
    body
  end

  def player_with_no_ids(name_with_pronouns)
    {
      'name_with_pronouns' => name_with_pronouns,
      'corp_id' => { 'faction' => nil, 'name' => nil },
      'runner_id' => { 'faction' => nil, 'name' => nil },
      'side' => nil,
      'side_label' => nil
    }
  end

  def bye_player
    { 'corp_id' => nil, 'name_with_pronouns' => '(Bye)', 'runner_id' => nil, 'side' => nil, 'side_label' => nil }
  end
end
