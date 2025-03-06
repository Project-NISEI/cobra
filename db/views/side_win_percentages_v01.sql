WITH
    base AS (
        SELECT
            s.tournament_id,
            s.number AS stage_number,
            CASE
                WHEN format = 0 THEN 2
                ELSE 1
            END AS num_expected_games,
            -- Since there are several ways to record scores, we can't always attribute a win to a side.
            -- We'll use this num_valid_games for the win rate numerator.
            CASE
                -- double-sided
                WHEN (format = 0 AND (score1_corp + score1_runner + score2_corp + score2_runner) > 0) THEN 2
                -- single-sided
                WHEN (format > 0 AND side > 0 AND (score1 + score2) > 0) THEN 1
                ELSE 0
            END as num_valid_games,

            CASE
                -- double-sided
                WHEN s.format = 0 AND ((score1_corp = 3 AND score2_corp = 0) OR (score1_corp = 0 AND score2_corp = 3)) THEN 1
                WHEN s.format = 0 AND score1_corp = 3 AND score2_corp = 3 THEN 2
                -- single-sided
                WHEN s.format > 0 AND score1_corp = 3 OR score2_corp = 3 THEN 1
            ELSE 0
            END AS num_corp_wins,

            CASE
                -- double-sided
                WHEN s.format = 0 AND ((score1_runner = 3 AND score2_runner = 0) OR (score1_runner = 0 AND score2_runner = 3)) THEN 1
                WHEN s.format = 0 AND score1_runner = 3 AND score2_runner = 3 THEN 2
                -- single-sided
                WHEN s.format > 0 AND score1_runner = 3 OR score2_runner = 3 THEN 1
            ELSE 0
            END AS num_runner_wins
        FROM stages AS s
            INNER JOIN rounds AS r ON s.id = r.stage_id
        INNER JOIN pairings AS p ON p.round_id = r.id
),
calculated AS (
    SELECT
        tournament_id,
        stage_number,
        num_expected_games,
        num_valid_games,
        CASE WHEN num_valid_games = 0 then 0 ELSE num_corp_wins END AS num_corp_wins,
        CASE WHEN num_valid_games = 0 then 0 ELSE num_runner_wins END AS num_runner_wins
    FROM base
)
SELECT
    tournament_id,
    stage_number,
    SUM(num_expected_games) AS num_games,
    SUM(num_valid_games) AS num_valid_games,
    CASE
        WHEN SUM(num_expected_games) > 0 THEN CAST(SUM(num_valid_games) AS FLOAT) / SUM(num_expected_games)
        ELSE 0.0
    END * 100 AS valid_game_percentage,
    SUM(num_corp_wins) AS num_corp_wins,
    CASE
        WHEN SUM(num_valid_games) > 0 THEN CAST(SUM(num_corp_wins) AS FLOAT) / SUM(num_valid_games)
        ELSE 0.0
    END * 100 AS corp_win_percentage,
    SUM(num_runner_wins) AS num_runner_wins,
    CASE
        WHEN SUM(num_valid_games) > 0 THEN CAST(SUM(num_runner_wins) AS FLOAT) / SUM(num_valid_games)
        ELSE 0.0
    END * 100 AS runner_win_percentage
FROM
    calculated
GROUP BY tournament_id, stage_number ORDER BY tournament_id, stage_number;

-- ORDER BY runner_win DESC, side;