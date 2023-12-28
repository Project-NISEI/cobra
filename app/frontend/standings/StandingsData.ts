import type {Identity} from "../identities/Identity";

export type StandingsData = {
    tournament_id: number;
    stages: Stage[];
}

export type Stage = {
    name: string;
    format: string;
    manual_seed: boolean;
    policy: StagePolicies;
    standings: Standing[];
}

export type Standing = {
    player: Player;
    seed: number;
    position: number;
    points: number;
    sos: number;
    extended_sos: number;
    corp_points: number;
    runner_points: number;
    manual_seed: number;
}

export type Player = {
    name_with_pronouns: string;
    corp_id: Identity | null;
    runner_id: Identity | null;
}

export type StagePolicies = {
    view_decks: boolean;
}
