export type PairingsData = {
    tournament_id: number;
    policy: TournamentPolicies;
    stages: Stage[];
}

export type TournamentPolicies = {
    update: boolean;
}

export type Stage = {
    details: StageDetails;
    name: string;
    rounds: Round[];
}

export type StageDetails = {}

export type Round = {
    details: RoundDetails;
    pairings: Pairing[];
    pairings_reported: number;
}

export type RoundDetails = {
    id: number;
    number: number;
}

export type Pairing = {
    details: PairingDetails;
    policy: PairingPolicies;
    player1: PlayerDetails;
    player2: PlayerDetails;
}

export type PairingDetails = {
    id: number;
    table_number: number;
    round_id: number;
}

export type PairingPolicies = {
    view_decks: boolean;
}

export type PlayerDetails = {
    name: string;
    pronouns: string;
}
