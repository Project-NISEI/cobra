export type Errors = Record<string, string>;

declare const Routes: {
  new_tournament_path: () => string;
};

export interface TournamentSettings {
  id?: number;
  name?: string;
  date?: string;
  private?: boolean;
  stream_url?: string;
  manual_seed?: boolean;
  self_registration?: boolean;
  allow_streaming_opt_out?: boolean;
  nrdb_deck_registration?: boolean;
  cut_deck_visibility?: string;
  swiss_deck_visibility?: string;
  swiss_format?: string;
  time_zone?: string;
  registration_starts?: string;
  tournament_starts?: string;
  tournament_type_id?: number;
  card_set_id?: number;
  format_id?: number;
  deckbuilding_restriction_id?: number;
  decklist_required?: boolean;
  organizer_contact?: string;
  event_link?: string;
  description?: string;
  official_prize_kit_id?: number;
  additional_prizes_description?: string;
  allow_self_reporting?: boolean;
}

export interface TournamentOptions {
  tournament_types: { id: number; name: string }[];
  formats: { id: number; name: string }[];
  card_sets: { id: number; name: string }[];
  deckbuilding_restrictions: { id: number; name: string }[];
  time_zones: { id: string; name: string }[];
  official_prize_kits: { id: number; name: string }[];
}

export interface TournamentSettingsData {
  tournament: TournamentSettings;
  options: TournamentOptions;
}

export function emptyTournamentOptions() {
  return {
    tournament_types: [],
    formats: [],
    card_sets: [],
    deckbuilding_restrictions: [],
    time_zones: [],
    official_prize_kits: [],
  };
}

export async function loadNewTournament(): Promise<TournamentSettingsData> {
  const response = await fetch(Routes.new_tournament_path(), {
    headers: { Accept: "application/json" },
    method: "GET",
  });
  return (await response.json()) as TournamentSettingsData;
}
