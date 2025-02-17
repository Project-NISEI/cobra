WITH corps AS (
    SELECT s.tournament_id,
        s.number AS stage_number,
        s.id AS stage_id,
        'corp' AS side,
        COALESCE(id.name, 'Unspecified') as identity,
        COALESCE(id.faction, 'Unspecified') as faction
    FROM stages s
        JOIN registrations r ON s.id = r.stage_id
        JOIN players p ON r.player_id = p.id
        LEFT JOIN identities AS id ON p.corp_identity_ref_id = id.id
),
runners AS (
    SELECT s.tournament_id,
        s.number AS stage_number,
        s.id AS stage_id,
        'runner' AS side,
        COALESCE(id.name, 'Unspecified') as identity,
        COALESCE(id.faction, 'Unspecified') as faction
    FROM stages s
        JOIN registrations r ON s.id = r.stage_id
        JOIN players p ON r.player_id = p.id
        JOIN identities AS id ON p.runner_identity_ref_id = id.id
),
combined AS (
    SELECT *
    FROM corps
    UNION ALL
    SELECT *
    FROM runners
),
swiss AS (
    SELECT tournament_id,
        stage_id,
        stage_number,
        side,
        identity,
        faction,
        COUNT(*) AS num_players
    FROM combined
    WHERE stage_number = 1
    GROUP BY 1,
        2,
        3,
        4,
        5,
        6
),
cut AS (
    SELECT
        tournament_id,
        stage_id,
        stage_number,
        side,
        identity,
        faction,
        COUNT(*) AS num_players
    FROM combined
    WHERE stage_number = 2
    GROUP BY
        tournament_id,
        stage_id,
        stage_number,
        side,
        identity,
        faction
)
SELECT
    s.tournament_id,
    s.side,
    s.identity,
    SUM(s.num_players) AS num_swiss_players,
    SUM(COALESCE(c.num_players, 0)) AS num_cut_players,
    (SUM(COALESCE(c.num_players, 0)) / SUM(s.num_players)) * 100 AS cut_conversion_percentage
FROM swiss s
    LEFT JOIN cut c USING (tournament_id, side, identity)
GROUP BY s.tournament_id, s.side, s.identity;