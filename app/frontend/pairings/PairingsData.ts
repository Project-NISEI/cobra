import type {Identity} from "../identities/Identity";

declare namespace Routes {
    function pairings_data_tournament_rounds_path(tournamentId: string): string;
}

export async function loadPairings(tournamentId: string): Promise<PairingsData> {
    const response = await fetch(
        Routes.pairings_data_tournament_rounds_path(tournamentId),
        {
            method: 'GET',
        }
    );
    return response.json();
}

export type PairingsData = {
    policy: TournamentPolicies;
    is_player_meeting: boolean;
    stages: Stage[];
}

export type TournamentPolicies = {
    update: boolean;
}

export type Stage = {
    name: string;
    format: string;
    rounds: Round[];
}

export type Round = {
    id: number;
    number: number;
    pairings: Pairing[];
    pairings_reported: number;
}

export type Pairing = {
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

export type PairingPolicies = {
    view_decks: boolean;
}

export type Player = {
    name_with_pronouns: string;
    side: string | null;
    side_label: string | null;
    corp_id: Identity | null;
    runner_id: Identity | null;
}
