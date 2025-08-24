import type { Identity } from "../identities/Identity";

export interface BracketPlayer {
  name_with_pronouns: string;
  side: string | null | undefined;
  corp_id?: Identity | null;
  runner_id?: Identity | null;
}

export interface BracketMatch {
  id?: number;
  table_number?: number;
  table_label?: string;
  successor_game?: number | null;
  score_label?: string | null;
  player1?: BracketPlayer | null;
  player2?: BracketPlayer | null;
  bracket_type?: string | null;
}
