import type {Identity} from "../identities/Identity";

export type StandingsData = {
    stages: Stage[];
}

export type Stage = {
    name: string;
    format: string;
    manual_seed: boolean;
    rounds_complete: number;
    any_decks_viewable: boolean;
    standings: Standing[];
}

export type Standing = {
    player: Player;
    policy: StandingPolicies;
    seed: number;
    position: number;
    points: number;
    sos: string;
    extended_sos: string;
    corp_points: number;
    runner_points: number;
    manual_seed: number;
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
