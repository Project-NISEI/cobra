# frozen_string_literal: true

require 'json'
require 'stackprof'

# This is a tournament simulator, which is useful for testing optimizations and forinspecting changes to pairing logic.
#
# Run this with bundle exec rspec spec/load_test.rb and specify any of the relevant environment variables
# to control the simulation.
#
# The following environment variables can be set to control the simulation:
#     DROPS_PER_ROUND -  The number of players that drop out of the tournament each round, defaults to 0
#     DSS_BOTH_TIE - The number of times both games in double-sided swiss end in a tie, defaults to 1.
#     DSS_P1_SWEEPS - The number of times player 1 sweeps in double-sided swiss, defaults to 25.
#     DSS_P1_WIN_AND_TIE - The number of times player 1 wins and ties in double-sided swiss, defaults to 2.
#     DSS_P2_SWEEPS - The number of times player 2 sweeps in double-sided swiss, defaults to 25.
#     DSS_P2_WIN_AND_TIE - The number of times player 2 wins and ties in double-sided swiss, defaults to 2.
#     DSS_SPLITS - The number of times a game ends in a split in double-sided swiss, defaults to 25.
#     FIRST_ROUND_BYES - The number of players with first round byes, defaults to 0
#     FORMAT - The swiss format to use, defaults to single_sided.
#     NUM_PLAYERS - The number of players in the tournament, defaults to 150
#     NUM_ROUNDS - The number of rounds in the tournament, defaults to 15
#     PROFILE - If set to '1' or 'true', runs the simulation in profiling mode using stackprof.
#     SSS_P1_WINS - The number of times player 1 wins in single-sided swiss, defaults to 48.
#     SSS_P2_WINS - The number of times player 2 wins in single-sided swiss, defaults to 48.
#     SSS_TIES - The number of times a game ends in a tie in single-sided swiss, defaults to 4.
#     WRITE_JSON_FILE - If set to '1' or 'true', writes the results to JSON files in the current directory.

# If profiles are requested, they the files will be written to the current directory.
# See https://github.com/tmm1/stackprof?tab=readme-ov-file#sampling for more info on working with stackprof.

# TODOs
#   Add env variable for number of wins vs. ties (and split wins on player 1 vs. player 2 as equally as can be)
#   Ensure number of byes is calculated correctly.
#   Use the proper set of scores per swiss format.

RSpec.describe 'load testing' do
  let(:write_json_file) { %w[1 true].include?(ENV['WRITE_JSON_FILE']) || false }
  let(:num_rounds) do
    if ENV['NUM_ROUNDS'].nil? || ENV['NUM_ROUNDS'].strip.empty? || ENV['NUM_ROUNDS'].strip.to_i == 0
      15
    else
      ENV['NUM_ROUNDS'].strip.to_i
    end
  end
  let(:num_players) do
    if ENV['NUM_PLAYERS'].nil? || ENV['NUM_PLAYERS'].strip.empty? || ENV['NUM_PLAYERS'].strip.to_i == 0
      150
    else
      ENV['NUM_PLAYERS'].strip.to_i
    end
  end
  let(:swiss_format) do
    if ENV['FORMAT'].nil? || ENV['FORMAT'].strip.empty?
      :single_sided
    else
      ENV['FORMAT'].strip.downcase.to_sym
    end
  end
  let(:num_drops_per_round) do
    if ENV['DROPS_PER_ROUND'].nil? || ENV['DROPS_PER_ROUND'].strip.empty?
      0
    else
      ENV['DROPS_PER_ROUND'].strip.to_i
    end
  end
  let(:num_first_round_byes) do
    if ENV['FIRST_ROUND_BYES'].nil? || ENV['FIRST_ROUND_BYES'].strip.empty?
      0
    else
      ENV['FIRST_ROUND_BYES'].strip.to_i
    end
  end

  let(:num_double_sided_player1_sweeps) do
    if ENV['DSS_P1_SWEEPS'].nil? || ENV['DSS_P1_SWEEPS'].strip.empty?
      25
    else
      ENV['DSS_P1_SWEEPS'].strip.to_i
    end
  end
  let(:num_double_sided_player2_sweeps) do
    if ENV['DSS_P2_SWEEPS'].nil? || ENV['DSS_P2_SWEEPS'].strip.empty?
      25
    else
      ENV['DSS_P2_SWEEPS'].strip.to_i
    end
  end
  let(:num_double_sided_splits) do
    if ENV['DSS_SPLITS'].nil? || ENV['DSS_SPLITS'].strip.empty?
      25
    else
      ENV['DSS_SPLITS'].strip.to_i
    end
  end
  let(:num_double_sided_p1_win_and_tie) do
    if ENV['DSS_P1_WIN_AND_TIE'].nil? || ENV['DSS_P1_WIN_AND_TIE'].strip.empty?
      2
    else
      ENV['DSS_P1_WIN_AND_TIE'].strip.to_i
    end
  end
  let(:num_double_sided_p2_win_and_tie) do
    if ENV['DSS_P2_WIN_AND_TIE'].nil? || ENV['DSS_P2_WIN_AND_TIE'].strip.empty?
      2
    else
      ENV['DSS_P2_WIN_AND_TIE'].strip.to_i
    end
  end
  let(:num_double_sided_both_tie) do
    if ENV['DSS_BOTH_TIE'].nil? || ENV['DSS_BOTH_TIE'].strip.empty?
      1
    else
      ENV['DSS_BOTH_TIE'].strip.to_i
    end
  end

  let(:num_single_sided_player1_wins) do
    if ENV['SSS_P1_WINS'].nil? || ENV['SSS_P1_WINS'].strip.empty?
      48
    else
      ENV['SSS_P1_WINS'].strip.to_i
    end
  end
  let(:num_single_sided_player2_wins) do
    if ENV['SSS_P2_WINS'].nil? || ENV['SSS_P2_WINS'].strip.empty?
      48
    else
      ENV['SSS_P2_WINS'].strip.to_i
    end
  end
  let(:num_single_sided_ties) do
    if ENV['SSS_TIES'].nil? || ENV['SSS_TIES'].strip.empty?
      4
    else
      ENV['SSS_TIES'].strip.to_i
    end
  end

  let(:tournament) { create(:tournament, swiss_format:) }
  let(:summary_results) do
    {
      swiss_format:,
      num_players:,
      num_rounds:,
      num_drops_per_round:,
      num_first_round_byes:,
      rounds: {}
    }
  end

  let(:scores) do
    scores = []
    if swiss_format == :single_sided
      # Single-sided swiss scores.
      num_single_sided_player1_wins.times do
        scores << [3, 0]
      end
      num_single_sided_player2_wins.times do
        scores << [0, 3]
      end
      num_single_sided_ties.times do
        scores << [1, 1]
      end
    else
      num_double_sided_player1_sweeps.times do
        scores << [6, 0]
      end
      num_double_sided_player2_sweeps.times do
        scores << [0, 6]
      end
      num_double_sided_splits.times do
        scores << [3, 3]
      end
      num_double_sided_p1_win_and_tie.times do
        scores << [4, 0]
      end
      num_double_sided_p2_win_and_tie.times do
        scores << [0, 4]
      end
      num_double_sided_both_tie.times do
        scores << [1, 1]
      end
    end

    scores
  end

  let(:rounds_against_opponent_counts_sql) do
    "WITH
      player1_pairings AS (
        SELECT
          p.player1_id AS player_id,
          p.player2_id AS opponent_id
        FROM
          pairings AS p
          INNER JOIN rounds AS r ON p.round_id = r.id
        WHERE r.tournament_id = $1 AND r.completed
      ),
      player2_pairings AS (
        SELECT
          p.player2_id AS player_id,
          p.player1_id AS opponent_id
        FROM
          pairings AS p
          INNER JOIN rounds AS r ON p.round_id = r.id
        WHERE r.tournament_id = $1 AND r.completed
      ),
      unified_pairings AS (
        SELECT *
        FROM player1_pairings
        UNION ALL
        SELECT *
        FROM player2_pairings
      )
      SELECT player_id, opponent_id, COUNT(*) AS num_games
      FROM unified_pairings
      WHERE player_id IS NOT NULL
      GROUP BY 1,2"
  end

  let(:player_score_summary) do
    "WITH
      player1_pairings AS (
        SELECT
          p.round_id,
          p.player1_id AS player_id,
          p.player1_id IS NULL OR p.player2_id IS NULL AS is_bye,
          CASE
              WHEN p.side = 1 THEN 'corp'
              ELSE 'runner'
          END AS side,
          p.score1 AS score,
          p.player2_id AS opponent_id,
          p.score2 AS opponent_score
        FROM
          pairings AS p
          INNER JOIN rounds AS r ON p.round_id = r.id
        WHERE r.tournament_id = $1 AND r.completed
      ),
      player2_pairings AS (
        SELECT
          p.round_id,
          p.player2_id AS player_id,
          p.player1_id IS NULL OR p.player2_id IS NULL AS is_bye,
          -- flip the logic since this is player 2
          CASE
              WHEN p.side = 1 THEN 'runner'
              ELSE 'corp'
          END AS side,
          p.score2 AS score,
          p.player1_id AS opponent_id,
          p.score1 AS opponent_score
        FROM
          pairings AS p
          INNER JOIN rounds AS r ON p.round_id = r.id
        WHERE r.tournament_id = $1 AND r.completed
      ),
      unified_pairings AS (
        SELECT *
        FROM player1_pairings
        UNION ALL
        SELECT *
        FROM player2_pairings
      )
      SELECT
        p.id as player_id,
        p.name as player_name,
        SUM(
          CASE
            WHEN COALESCE(up.is_bye, FALSE) THEN 1
            ELSE 0
          END) AS num_byes,
        SUM(CASE WHEN NOT up.is_bye AND up.side = 'corp' THEN 1 ELSE 0 END) AS num_corp_games,
        SUM(CASE WHEN NOT up.is_bye AND up.side = 'runner' THEN 1 ELSE 0 END) AS num_runner_games,
        SUM(COALESCE(up.score, 0)) AS total_score
      FROM
        players AS p
        LEFT JOIN unified_pairings AS up ON p.id = up.player_id
      WHERE p.active AND p.tournament_id = $1
      GROUP BY 1,2
      "
  end

  let(:current_round_pairings_sql) do
    "WITH
      player1_pairings AS (
        SELECT
          r.number AS round_number,
          p.round_id,
          p.player1_id AS player_id,
          p.player1_id IS NULL
          OR p.player2_id IS NULL AS is_bye,
          CASE
              WHEN p.side = 1 THEN 'corp'
              ELSE 'runner'
          END AS side,
          p.score1 AS score,
          p.player2_id AS opponent_id,
          p.score2 AS opponent_score
        FROM
          pairings AS p
          INNER JOIN rounds AS r ON p.round_id = r.id
        WHERE r.tournament_id = $1 AND NOT r.completed
      ),
      player2_pairings AS (
        SELECT
          r.number AS round_number,
          p.round_id,
          p.player2_id AS player_id,
          p.player1_id IS NULL
          OR p.player2_id IS NULL AS is_bye,
          -- flip the logic since this is player 2
          CASE
              WHEN p.side = 1 THEN 'runner'
              ELSE 'corp'
          END AS side,
          p.score2 AS score,
          p.player1_id AS opponent_id,
          p.score1 AS opponent_score
        FROM
          pairings AS p
          INNER JOIN rounds AS r ON p.round_id = r.id
        WHERE r.tournament_id = $1 AND NOT r.completed
      )
      SELECT * FROM player1_pairings
      UNION ALL
      SELECT * FROM player2_pairings"
  end

  def timer
    (Time.zone.now - (@start || Time.zone.now)).seconds.tap do
      @start = Time.zone.now
    end
  end

  it 'can handle load' do
    puts 'Starting simulation with config:'
    puts "  swiss_format:                    #{swiss_format}"
    puts "  num_players:                     #{num_players}"
    puts "  num_rounds:                      #{num_rounds}"
    puts "  num_drops_per_round:             #{num_drops_per_round}"
    puts "  num_first_round_byes:            #{num_first_round_byes}"
    if swiss_format == :single_sided
      summary_results.merge!(
        num_single_sided_player1_wins:,
        num_single_sided_player2_wins:,
        num_single_sided_ties:
      )
      puts "  num_single_sided_player1_wins:   #{num_single_sided_player1_wins}"
      puts "  num_single_sided_player2_wins:   #{num_single_sided_player2_wins}"
      puts "  num_single_sided_ties:           #{num_single_sided_ties}"
    else
      summary_results.merge!(
        num_double_sided_both_tie:,
        num_double_sided_p1_win_and_tie:,
        num_double_sided_p2_win_and_tie:,
        num_double_sided_player1_sweeps:,
        num_double_sided_player2_sweeps:,
        num_double_sided_splits:
      )
      puts "  num_double_sided_both_tie:       #{num_double_sided_both_tie}"
      puts "  num_double_sided_p1_win_and_tie: #{num_double_sided_p1_win_and_tie}"
      puts "  num_double_sided_p2_win_and_tie: #{num_double_sided_p2_win_and_tie}"
      puts "  num_double_sided_player1_sweeps: #{num_double_sided_player1_sweeps}"
      puts "  num_double_sided_player2_sweeps: #{num_double_sided_player2_sweeps}"
      puts "  num_double_sided_splits:         #{num_double_sided_splits}"
    end
    timer
    sign_in tournament.user

    puts 'Creating players'
    num_players.times { create(:player, tournament:) }

    # Assign the first round byes if requested.
    if num_first_round_byes > 0
      tournament.players.active.shuffle.take(num_first_round_byes).each { |p| p.update(first_round_bye: true) }
    end

    expect(tournament.players.count).to equal(num_players)
    time_taken = timer
    summary_results[:tournament_setup_time_seconds] = time_taken
    puts "\tTournament setup done. Took #{time_taken} seconds"

    active_players = num_players
    num_rounds.times do |i|
      puts "Round #{i + 1}"
      round = nil

      puts "\tPairing #{tournament.players.active.count} players"
      if ENV['PROFILE'] == '1'
        StackProf.run(mode: :cpu, out: "pair-round-#{i + 1}", raw: true) do
          round = tournament.pair_new_round!
        end
      else
        round = tournament.pair_new_round!
      end

      time_taken = timer
      summary_results[:rounds][round.number] = {}
      summary_results[:rounds][round.number][:pairing_time_seconds] = time_taken
      puts "\t\tDone pairing round #{round.number}. Took #{timer} seconds"

      expected_pairings = 0
      if num_first_round_byes > 0 && i == 0
        # If there are first round byes, we expect the number of pairings to be less than half the players.
        expected_pairings = ((active_players - num_first_round_byes) / 2.0).ceil + num_first_round_byes
      else
        expected_pairings = (active_players / 2.0).ceil
      end
      expect(round.pairings.count).to eq(expected_pairings)

      players = round.pairings.map(&:players).flatten
      expect(players.map(&:id) - [nil]).to match_array(tournament.players.active.map(&:id))
      if i == 0
        # The first round can have multiple byes if there are players with first round byes.
        expect(players.select { |p| p.is_a? NilPlayer }.length).to be < (2 + num_first_round_byes)
      else
        # After the first round, we should only have at most a single bye.
        expect(players.select { |p| p.is_a? NilPlayer }.length).to be < 2
      end

      # How many times have players played each opponent they have faced at the start of this round?
      rounds_against_opponent_counts = {}
      results = ActiveRecord::Base.connection.select_all(rounds_against_opponent_counts_sql, nil, [round.tournament_id])
      results.each do |r|
        rounds_against_opponent_counts[r['num_games']] = 0 unless rounds_against_opponent_counts.key?(r['num_games'])
        rounds_against_opponent_counts[r['num_games']] += 1
      end

      # Summarize Number of Byes and Side Bias for completed rounds at beginning of round.
      # No need to populate this for the first round, since there are no completed rounds yet.
      results = ActiveRecord::Base.connection.select_all(player_score_summary, nil, [round.tournament_id])
      # We only expect 0 or 1 byes for a player
      num_byes = { 0 => 0, 1 => 0 }
      side_bias = { -1 => 0, 0 => 0, 1 => 0 }
      scores_by_player = {}
      score_counts = {}
      results.each do |r|
        num_byes[r['num_byes']] = 0 unless num_byes.key?(r['num_byes'])
        num_byes[r['num_byes']] += 1

        bias = r['num_corp_games'] - r['num_runner_games']
        side_bias[bias] = 0 unless side_bias.key?(bias)
        side_bias[bias] += 1
        scores_by_player[r['player_id']] = r['total_score']
        score_counts[r['total_score']] = 0 unless score_counts.key?(r['total_score'])
        score_counts[r['total_score']] += 1
      end

      # TODO(plural): Add current round number of byes.
      results = ActiveRecord::Base.connection.select_all(current_round_pairings_sql, nil, [round.tournament_id])
      pairing_types = { up: 0, down: 0, same: 0, bye: 0 }
      results.each do |r|
        next if r['player_id'].nil?

        if r['opponent_id'].nil?
          pairing_types[:bye] += 1
        else
          player_score = scores_by_player[r['player_id']]
          opponent_score = scores_by_player[r['opponent_id']]
          if player_score > opponent_score
            pairing_types[:down] += 1
          elsif player_score < opponent_score
            pairing_types[:up] += 1
          else
            pairing_types[:same] += 1
          end
        end
      end

      cumulative = {}
      if round.number > 1
        cumulative = {
          rounds_against_opponent_counts: rounds_against_opponent_counts.sort_by { |k, _v| k.to_i }.to_h,
          players_by_bye_count: num_byes.sort_by { |k, _v| k.to_i }.to_h,
          score_counts: score_counts.sort_by { |k, _v| k.to_i }.to_h,
          side_bias: side_bias.sort_by { |k, _v| k.to_i }.to_h
        }
      end

      summary_results[:rounds][round.number].merge!(
        pairing_types: pairing_types.sort_by { |k, _v| k }.to_h,
        cumulative:
      )

      puts "Start of round #{round.number}"
      puts "  Num games vs. same opponent: #{rounds_against_opponent_counts}"
      puts "  Points summary: #{score_counts}"
      puts "  Pairing directions: #{pairing_types}"
      puts "  Number of byes per player: #{num_byes}"
      puts "  Side bias: #{side_bias}"

      puts "\tGenerating results"
      ActiveRecord::Base.transaction do
        round.pairings.each do |p|
          # score = [[6, 0], [4, 1], [3, 3], [0, 6]].sample
          score = scores.sample # [[3, 0], [0, 3], [1, 1]].sample
          # visit tournament_rounds_path(tournament)
          p.update(score1: score.first, score2: score.last)
        end

        # Drop 3 players at random
        tournament.players.active.shuffle.take(num_drops_per_round).each { |p| p.update(active: false) }
        active_players -= num_drops_per_round
        round.update(completed: true)
      end

      time_taken = timer
      summary_results[:rounds][round.number][:result_generation_time_seconds] = time_taken
      puts "\t\tDone generating results. Took #{time_taken} seconds"

      puts "\tCalculating standings"
      # 10.times do
      visit standings_tournament_players_path(tournament)
      time_taken = timer
      summary_results[:rounds][round.number][:standings_page_load_time_seconds] = time_taken
      puts "\t\tDone. Took #{time_taken} seconds"
      # end
    end

    if write_json_file
      json_file_name = "tournament_simulation_results-#{Time.now.to_i}.json"
      puts JSON.pretty_generate(summary_results)
      File.write(json_file_name, JSON.pretty_generate(summary_results))
      puts "Wrote JSON results to #{json_file_name}"
    end
  end
end
