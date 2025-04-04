import type {Identity} from "../identities/Identity";

declare const Routes: {
    pairings_data_tournament_rounds_path: (tournamentId: string) => string;
};

export async function loadPairings(tournamentId: string): Promise<PairingsData> {
    const response = await fetch(
        Routes.pairings_data_tournament_rounds_path(tournamentId),
        {
            method: 'GET',
        }
    );
    return await response.json() as PairingsData;
}

export interface PairingsData {
    policy: TournamentPolicies;
    is_player_meeting: boolean;
    stages: Stage[];
}

export interface TournamentPolicies {
    update: boolean;
}

export interface Stage {
    name: string;
    format: string;
    rounds: Round[];
}

export interface Round {
    id: number;
    number: number;
    pairings: Pairing[];
    pairings_reported: number;
}

export interface Pairing {
    id: number;
    table_number: number;
    table_label: string;
    policy: PairingPolicies;
    player1: Player;
    player2: Player;
    score_label: string;
    intentional_draw: boolean;
    two_for_one: boolean;
}

export interface PairingPolicies {
    view_decks: boolean;
}

export interface Player {
    name_with_pronouns: string;
    side: string | null;
    side_label: string | null;
    corp_id: Identity | null;
    runner_id: Identity | null;
}
