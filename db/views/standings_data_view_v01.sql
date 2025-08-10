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
        INNER JOIN stages AS s ON r.stage_id = s.id -- Only calculate side bias for single-sided swiss stages
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
)
SELECT t.id AS tournament_id,
    t.manual_seed,
    EXISTS (
        SELECT id
        FROM rounds
    ) AS is_player_meeting,
    sft.stage_id,
    sft.position,
    sft.player_id,
    sft.name,
    sft.pronouns,
    corp_id.name AS corp_id_name,
    corp_id.faction AS corp_id_faction,
    runner_id.name AS runner_id_name,
    runner_id.faction AS runner_id_faction,
    sft.active,
    sft.points,
    sft.corp_points,
    sft.runner_points,
    sft.bye_points,
    sft.sos,
    sft.extended_sos,
    sb.side_bias AS side_bias
FROM tournaments AS t
    INNER JOIN standings_for_tournament AS sft ON sft.tournament_id = t.id
    INNER JOIN players AS p ON sft.player_id = p.id
    LEFT JOIN identities AS corp_id ON p.corp_identity_ref_id = corp_id.id
    LEFT JOIN identities AS runner_id ON p.runner_identity_ref_id = runner_id.id
    LEFT JOIN side_bias AS sb ON sb.stage_id = sft.stage_id
    AND sft.player_id = sb.player_id;