WITH two_player_biases AS (
    SELECT r.stage_id,
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
    FROM pairings AS p
        INNER JOIN rounds AS r ON p.round_id = r.id
        INNER JOIN stages AS s ON r.stage_id = s.id
    -- Only calculate side bias for single-sided swiss stages
    WHERE s.format = 2
),
flattened AS (
    SELECT stage_id,
        player1_id as player_id,
        player1_side_bias AS side_bias
    FROM two_player_biases
    UNION ALL
    SELECT stage_id,
        player2_id AS player_id,
        player2_side_bias AS side_bias
    FROM two_player_biases
),
side_bias AS (
    SELECT stage_id,
        player_id,
        SUM(side_bias) AS side_bias
    FROM flattened
    WHERE player_id IS NOT NULL
    GROUP BY stage_id,
        player_id
),
standings_for_tournament AS (
    SELECT s.tournament_id,
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
    FROM standing_rows AS sr
        INNER JOIN players AS p ON sr.player_id = p.id
        INNER JOIN stages AS s ON s.id = sr.stage_id
),
rounds_for_stages AS (
    SELECT s.id AS stage_id,
        s.number AS stage_number,
        COUNT(DISTINCT r.id) AS num_rounds,
        COUNT(DISTINCT r.id) FILTER (WHERE r.completed) AS num_rounds_completed
    FROM stages AS s
        LEFT JOIN rounds AS r ON s.id = r.stage_id
    GROUP BY s.id,
        s.number
),
stages_with_players AS (
    SELECT s.tournament_id,
        s.id AS stage_id,
        s.number AS stage_number,
        s.format AS stage_format,
        r.id AS registration_id,
        p.id AS player_id,
        p.name AS player_name,
        p.pronouns AS player_pronouns,
        p.active AS player_active,
        corp_id.name AS corp_id_name,
        corp_id.faction AS corp_id_faction,
        runner_id.name AS runner_id_name,
        runner_id.faction AS runner_id_faction
    FROM stages AS s
        INNER JOIN registrations AS r ON s.id = r.stage_id
        INNER JOIN players AS p ON r.player_id = p.id
        LEFT JOIN identities AS corp_id ON p.corp_identity_ref_id = corp_id.id
        LEFT JOIN identities AS runner_id ON p.runner_identity_ref_id = runner_id.id
)
SELECT
    t.id AS tournament_id,
    t.manual_seed,
    rfs.num_rounds,
    -- Set the player meeting field if it is the first stage and there are no rounds yet.
    rfs.stage_number = 1 AND rfs.num_rounds = 0 AS is_player_meeting,
    rfs.num_rounds_completed,
    swp.stage_id,
    swp.stage_format,
    swp.stage_number,
    swp.player_id,
    swp.player_name,
    swp.player_pronouns,
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
FROM tournaments AS t
    INNER JOIN stages_with_players AS swp ON swp.tournament_id = t.id
    INNER JOIN rounds_for_stages AS rfs ON rfs.stage_id = swp.stage_id
    LEFT JOIN standings_for_tournament AS sft ON sft.tournament_id = swp.tournament_id
    AND sft.stage_id = swp.stage_id
    AND sft.player_id = swp.player_id
    LEFT JOIN side_bias AS sb ON sb.stage_id = sft.stage_id
    AND sft.player_id = sb.player_id;
