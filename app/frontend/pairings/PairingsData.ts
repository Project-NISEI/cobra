import type { Identity } from "../identities/Identity";

declare const Routes: {
  pairings_data_tournament_rounds_path: (tournamentId: number) => string;
  pairing_presets_tournament_round_pairing_path: (
    tournamentId: number,
    roundId: number,
    id: number,
  ) => string;
};

export async function loadPairings(
  tournamentId: number,
): Promise<PairingsData> {
  const response = await fetch(
    Routes.pairings_data_tournament_rounds_path(tournamentId),
    {
      method: "GET",
    },
  );

  return (await response.json()) as PairingsData;
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
  self_report: SelfReport | null;
  successor_game: number | null;
  bracket_type: string | null;
  ui_metadata: UiMetadata;
}

export interface UiMetadata {
  row_highlighted: boolean;
}


export interface SelfReport {
  report_player_id: number;
  score1: number;
  score2: number;
  intentional_draw: boolean;
  label: string | null;
}

export interface PairingPolicies {
  view_decks: boolean;
  self_report: boolean;
}

export interface Player {
  name_with_pronouns: string;
  side: string | null;
  user_id: string | null;
  side_label: string | null;
  corp_id: Identity | null;
  runner_id: Identity | null;
}
