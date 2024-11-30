# frozen_string_literal: true

module PairingStrategies
  class Base
    attr_reader :round, :random

    delegate :stage, to: :round

    def initialize(round, random = Random)
      @round = round
      @random = random
    end

    def players
      @players ||= build_player_summary.select { |_, v| v.active }
    end

    # SQL to use as input for building up scoring and pairing data efficiently.
    # This does 2 main things:
    #   Gives us a single pass over all the players in the tournament
    #   Gives us a row per player, per pairing, if there are any pairings yet.
    #   Since pairings have 2 players, either the SQL or the ruby code need to
    #   normalize things by player.
    #   Doing this in the SQL means we can make a single pass over the results and build up
    #   the appropriate summary for the player, including:
    #   - id, name
    #   - first round bye and fixed table number (if present)
    #   - side, opponent info and score for each pairing.
    PLAYER_SUMMARY_SQL = "
      WITH player1_pairings AS (
        SELECT
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
          CASE
              WHEN p.side = 1 THEN 'runnner'
              ELSE 'corp'
          END AS opponent_side
        FROM
          pairings AS p
          INNER JOIN rounds AS r ON p.round_id = r.id
        WHERE r.tournament_id = $1 AND r.completed
      ),
      player2_pairings AS (
        SELECT
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
          CASE
              WHEN p.side = 1 THEN 'corp'
              ELSE 'runner'
          END AS opponent_side
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
        p.active,
        p.first_round_bye,
        p.fixed_table_number,
        COALESCE(up.is_bye, FALSE) as is_bye,
        up.side,
        COALESCE(up.score, 0) AS score,
        up.opponent_id,
        up.opponent_side
      FROM
        players AS p
        LEFT JOIN unified_pairings AS up ON p.id = up.player_id
      WHERE p.tournament_id = $1
      "

    def build_player_summary
      results = ActiveRecord::Base.connection.select_all(PLAYER_SUMMARY_SQL, nil, [round.tournament_id])

      player_summary = {}
      results.each do |p|
        p.symbolize_keys!

        unless player_summary.key?(p[:player_id])
          player_summary[p[:player_id]] =
            PlainPlayer.new(p[:player_id], p[:player_name], p[:active], p[:first_round_bye])
        end

        plain_player = player_summary[p[:player_id]]
        plain_player.points += p[:score]
        plain_player.had_bye = true if p[:is_bye]
        plain_player.fixed_table_number = p[:fixed_table_number] unless p[:fixed_table_number].nil?

        # Byes don't affect side bias or the opponents hash.
        next if p[:is_bye] || p[:opponent_id].nil?

        plain_player.side_bias += (p[:side] == 'corp' ? 1 : -1)
        plain_player.add_opponent(p[:opponent_id], p[:side])
      end

      player_summary
    end
  end
end
