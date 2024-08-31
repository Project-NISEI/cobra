import type {Identity} from "../identities/Identity";

declare namespace Routes {
    function standings_data_tournament_players_path(tournamentId: string): string;
}

export async function loadStandings(tournamentId: string): Promise<StandingsData> {
    const response = await fetch(
        Routes.standings_data_tournament_players_path(tournamentId),
        {
            method: 'GET',
        }
    );
    return response.json();
}

export type StandingsData = {
    manual_seed: boolean;
    stages: Stage[];
}

export type Stage = {
    name: string;
    format: string;
    rounds_complete: number;
    any_decks_viewable: boolean;
}

export type SwissStage = Stage & {
    standings: SwissStanding[];
}

export type CutStage = Stage & {
    standings: CutStanding[];
}

export type SwissStanding = {
    player: Player;
    policy: StandingPolicies;
    position: number;
    points: number;
    sos: string;
    extended_sos: string;
    corp_points: number;
    runner_points: number;
    manual_seed: number | null;
}

export type CutStanding = {
    player: Player | null;
    policy: StandingPolicies;
    seed: number;
    position: number;
}

export type Player = {
    id: number;
    name_with_pronouns: string;
    corp_id: Identity | null;
    runner_id: Identity | null;
}

export type StandingPolicies = {
    view_decks: boolean;
}
