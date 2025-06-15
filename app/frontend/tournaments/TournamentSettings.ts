export type Errors = Record<string, string[]>;

declare const Routes: {
  new_tournament_path: () => string;
  tournaments_path: () => string;
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

export interface FeatureFlags {
  single_sided_swiss?: boolean;
  nrdb_deck_registration?: boolean;
  allow_self_reporting?: boolean;
  streaming_opt_out?: boolean;
}

export interface TournamentSettingsData {
  tournament: TournamentSettings;
  options: TournamentOptions;
  feature_flags: FeatureFlags;
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

export interface TournamentCreateResponse {
  id: number;
  name: string;
  url: string;
}

export interface TournamentCreateErrorResponse {
  errors: Errors;
}

function getCSRFToken(): string {
  const metaTag = document.querySelector('meta[name="csrf-token"]');
  if (metaTag instanceof HTMLMetaElement) {
    return metaTag.content;
  }
  return "";
}

export async function createTournament(
  tournament: TournamentSettings,
): Promise<TournamentCreateResponse> {
  const response = await fetch(Routes.tournaments_path(), {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-CSRF-Token": getCSRFToken(),
    },
    body: JSON.stringify({ tournament }),
  });

  if (!response.ok) {
    if (response.status === 422) {
      const errorData =
        (await response.json()) as TournamentCreateErrorResponse;
      throw new ValidationError(errorData.errors);
    }
    throw new Error(
      `HTTP ${response.status.toString()}: ${response.statusText}`,
    );
  }

  return (await response.json()) as TournamentCreateResponse;
}

export class ValidationError extends Error {
  constructor(public errors: Errors) {
    super("Validation failed");
    this.name = "ValidationError";
  }
}
