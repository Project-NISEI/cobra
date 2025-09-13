-- This view summarizes all of the data needed to power standings views in a single query.
-- The overall flow for the view is:
--   1: Calculate Side Bias for any single sided swiss stages.
--   2: Enhance standings data with relevant information per round.
--   3: Expand and join information per stage, separated into swiss and cut stages.
--   4: Combine the swiss and cut stages to produce the final summary.
--
-- This view does duplicate some information for tournaments and rounds in favor of enabling
-- a single query from the server to power the standings views.
-- The application has the responsibility of transforming this tabular view into any nested object structures.
WITH
-- Calculating side bias has 3 steps.
-- Side bias step 1: Emit side bias for each pairing with stage and player ids for Single-sided Swiss stages.
two_player_side_bias_by_pairing AS (
    SELECT
        r.stage_id,
        p.player1_id,
        CASE
            WHEN side = 1 THEN 1
            WHEN side = 2 THEN -1
            ELSE 0
        END AS player1_side_bias,
        p.player2_id,
        CASE
            WHEN side = 1 THEN -1
            WHEN side = 2 THEN 1
            ELSE 0
        END AS player2_side_bias
    FROM
        pairings AS p
        INNER JOIN rounds AS r ON p.round_id = r.id
        INNER JOIN stages AS s ON r.stage_id = s.id
    -- Only calculate side bias for completed single-sided swiss stages
    WHERE
        s.format = 2
        AND r.completed
),
-- Side bias step 2: Normalize two_player_side_bias_by_pairing to stage_id and player_id.
single_player_side_bias_by_stage AS (
    SELECT
        stage_id,
        player1_id as player_id,
        player1_side_bias AS side_bias
    FROM
        two_player_side_bias_by_pairing
    UNION ALL
    SELECT
        stage_id,
        player2_id AS player_id,
        player2_side_bias AS side_bias
    FROM
        two_player_side_bias_by_pairing
),
-- Side bias step 3: SUM side bias by stage id and player, removing any byes (NULL player_id).
side_bias AS (
    SELECT
        stage_id,
        player_id,
        SUM(side_bias) AS side_bias
    FROM
        single_player_side_bias_by_stage
    WHERE
        player_id IS NOT NULL
    GROUP BY
        stage_id,
        player_id
),
-- Decorate standings records with some player and stage information.
standings_for_tournament AS (
    SELECT
        s.tournament_id,
        s.id AS stage_id,
        s.format AS stage_format,
        sr.position,
        sr.player_id,
        p.name,
        p.pronouns,
        p.active,
        sr.points,
        sr.corp_points,
        sr.runner_points,
        sr.bye_points,
        sr.sos,
        sr.extended_sos
    FROM
        standing_rows AS sr
        INNER JOIN players AS p ON sr.player_id = p.id
        INNER JOIN stages AS s ON s.id = sr.stage_id
),
-- Compute number of rounds paired and rounds completed per stage.
rounds_for_stages AS (
    SELECT
        s.id AS stage_id,
        s.number AS stage_number,
        COUNT(DISTINCT r.id) AS num_rounds,
        COUNT(DISTINCT r.id) FILTER (WHERE r.completed) AS num_rounds_completed
    FROM
        stages AS s
        LEFT JOIN rounds AS r ON s.id = r.stage_id
    GROUP BY
        s.id,
        s.number
),
-- Create a table for the number of players in the cut for any cut stage.
-- This does not have any player informatino, but is used to ensure we have a
-- row per player in the cut, even before anyone is eliminated and we have any cut standings.
cut_positions AS (
    SELECT
        stage_id,
        seed
    FROM
        registrations AS r
        INNER JOIN stages AS s ON r.stage_id = s.id
    WHERE
        -- only elimination stages
        s.format IN (1,3)
),
-- Create a table for all cut players who have been eliminated and have a final position in the cut.
cut_players AS (
    SELECT
        cp.stage_id,
        cp.seed AS position,
        sr.player_id,
        r.seed,
        r.id AS registration_id
    FROM
        cut_positions AS cp
        LEFT JOIN standing_rows AS sr ON cp.stage_id = sr.stage_id AND cp.seed = sr.position
        LEFT JOIN registrations AS r ON sr.stage_id = r.stage_id AND sr.player_id = r.player_id
),
-- Expand the cut players with their position and identities.
cut_stages_with_players AS (
    SELECT
        s.tournament_id,
        s.id AS stage_id,
        s.number AS stage_number,
        s.format AS stage_format,
        cp.registration_id AS registration_id,
        cp.position AS position,
        r.seed AS seed,
        p.id AS player_id,
        p.name AS player_name,
        p.pronouns AS player_pronouns,
        p.active AS player_active,
        p.user_id AS player_user_id,
        p.manual_seed AS player_manual_seed,
        corp_id.name AS corp_id_name,
        corp_id.faction AS corp_id_faction,
        runner_id.name AS runner_id_name,
        runner_id.faction AS runner_id_faction
    FROM
        cut_players AS cp
        INNER JOIN stages AS s ON cp.stage_id = s.id
        LEFT JOIN registrations AS r ON cp.registration_id = r.id
        LEFT JOIN players AS p ON r.player_id = p.id
        LEFT JOIN identities AS corp_id ON p.corp_identity_ref_id = corp_id.id
        LEFT JOIN identities AS runner_id ON p.runner_identity_ref_id = runner_id.id
),
-- Expand the swsiss players with their position and identities.
swiss_stages_with_players AS (
    SELECT
        s.tournament_id,
        s.id AS stage_id,
        s.number AS stage_number,
        s.format AS stage_format,
        r.id AS registration_id,
        r.seed AS seed,
        p.id AS player_id,
        p.name AS player_name,
        p.pronouns AS player_pronouns,
        p.active AS player_active,
        p.user_id AS player_user_id,
        p.manual_seed AS player_manual_seed,
        corp_id.name AS corp_id_name,
        corp_id.faction AS corp_id_faction,
        runner_id.name AS runner_id_name,
        runner_id.faction AS runner_id_faction
    FROM
        stages AS s
        INNER JOIN registrations AS r ON s.id = r.stage_id
        INNER JOIN players AS p ON r.player_id = p.id
        LEFT JOIN identities AS corp_id ON p.corp_identity_ref_id = corp_id.id
        LEFT JOIN identities AS runner_id ON p.runner_identity_ref_id = runner_id.id
    WHERE
        -- only swiss stages
        s.format IN (0, 2)
),
-- Produce the final, expanded version of swiss standings, including some repeated summary info about the tournaments and rounds.
expanded_swiss_standings AS (
    SELECT
        t.id AS tournament_id,
        t.swiss_deck_visibility,
        t.cut_deck_visibility,
        t.user_id AS tournament_user_id,
        COALESCE(t.manual_seed, false) AS tournament_manual_seed,
        rfs.num_rounds,
        -- Set the player meeting field if it is the first stage and there are no rounds yet.
        rfs.stage_number = 1 AND rfs.num_rounds = 0 AS is_player_meeting,
        rfs.num_rounds_completed,
        swp.stage_id,
        swp.stage_format,
        swp.stage_number,
        swp.player_id,
        swp.player_user_id,
        swp.player_name,
        swp.player_pronouns,
        swp.player_manual_seed,
        swp.seed,
        swp.corp_id_name,
        swp.corp_id_faction,
        swp.runner_id_name,
        swp.runner_id_faction,
        swp.player_active,
        sft.position,
        sft.points,
        sft.corp_points,
        sft.runner_points,
        sft.bye_points,
        sft.sos,
        sft.extended_sos,
        sb.side_bias AS side_bias
    FROM
        tournaments AS t
        INNER JOIN swiss_stages_with_players AS swp ON swp.tournament_id = t.id
        INNER JOIN rounds_for_stages AS rfs ON rfs.stage_id = swp.stage_id
        LEFT JOIN standings_for_tournament AS sft ON sft.tournament_id = swp.tournament_id
        AND sft.stage_id = swp.stage_id
        AND sft.player_id = swp.player_id
        LEFT JOIN side_bias AS sb ON sb.stage_id = sft.stage_id
        AND sft.player_id = sb.player_id
),
-- Produce the final, expanded version of cut standings, including some repeated summary info about the tournaments and rounds.
expanded_cut_standings AS (
    SELECT
        t.id AS tournament_id,
        t.swiss_deck_visibility,
        t.cut_deck_visibility,
        t.user_id AS tournament_user_id,
        COALESCE(t.manual_seed, false) AS tournament_manual_seed,
        rfs.num_rounds,
        -- Set the player meeting field if it is the first stage and there are no rounds yet.
        rfs.stage_number = 1 AND rfs.num_rounds = 0 AS is_player_meeting,
        rfs.num_rounds_completed,
        cwp.stage_id,
        cwp.stage_format,
        cwp.stage_number,
        cwp.player_id,
        cwp.player_user_id,
        cwp.player_name,
        cwp.player_pronouns,
        cwp.player_manual_seed,
        cwp.seed,
        cwp.corp_id_name,
        cwp.corp_id_faction,
        cwp.runner_id_name,
        cwp.runner_id_faction,
        cwp.player_active,
        cwp.position,
        sft.points,
        sft.corp_points,
        sft.runner_points,
        sft.bye_points,
        sft.sos,
        sft.extended_sos,
        sb.side_bias AS side_bias
    FROM
        tournaments AS t
        INNER JOIN cut_stages_with_players AS cwp ON cwp.tournament_id = t.id
        INNER JOIN rounds_for_stages AS rfs ON rfs.stage_id = cwp.stage_id
        LEFT JOIN standings_for_tournament AS sft ON sft.tournament_id = cwp.tournament_id
        AND sft.stage_id = cwp.stage_id
        AND sft.player_id = cwp.player_id
        LEFT JOIN side_bias AS sb ON sb.stage_id = sft.stage_id
        AND sft.player_id = sb.player_id
)
-- Combine the swiss and cut stage summaries for the final result.
SELECT * FROM expanded_swiss_standings
UNION ALL
SELECT * FROM expanded_cut_standings
;
