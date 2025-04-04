import type {Identity} from "../identities/Identity";

declare const Routes: {
    standings_data_tournament_players_path: (tournamentId: string) => string;
};

export async function loadStandings(tournamentId: string): Promise<StandingsData> {
    const response = await fetch(
        Routes.standings_data_tournament_players_path(tournamentId),
        {
            method: 'GET',
        }
    );
    return response.json();
}

export interface StandingsData {
    manual_seed: boolean;
    stages: Stage[];
}

export interface Stage {
    name: string;
    format: string;
    rounds_complete: number;
    any_decks_viewable: boolean;
}

export interface SwissStage extends Stage {
    standings: SwissStanding[];
}

export interface CutStage extends Stage {
    standings: CutStanding[];
}

export interface SwissStanding {
    player: Player;
    policy: StandingPolicies;
    position: number;
    points: number;
    sos: string;
    extended_sos: string;
    corp_points: number;
    runner_points: number;
    manual_seed: number | null;
    side_bias: number | null;
}

export interface CutStanding {
    player: Player | null;
    policy: StandingPolicies;
    seed: number;
    position: number;
}

export interface Player {
    id: number;
    name_with_pronouns: string;
    corp_id: Identity | null;
    runner_id: Identity | null;
}

export interface StandingPolicies {
    view_decks: boolean;
}
