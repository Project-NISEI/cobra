export type Errors = Record<string, string[]>;

declare const Routes: {
  new_demo_form_tournaments_path: () => string;
  create_demo_tournaments_path: () => string;
  tournaments_path: () => string;
};

export interface DemoTournamentSettings {
  id?: number;
  name?: string;
  num_players?: number;
  num_first_round_byes?: number;
  assign_ids?: boolean;
  swiss_format?: string;
}

export interface DemoTournamentOptions {
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

export interface DemoTournamentSettingsData {
  tournament: DemoTournamentSettings;
  options: DemoTournamentOptions;
  feature_flags: FeatureFlags;
  csrf_token: string;
}

export function emptyDemoTournamentOptions(): DemoTournamentOptions {
  return {
    tournament_types: [],
    formats: [],
    card_sets: [],
    deckbuilding_restrictions: [],
    time_zones: [],
    official_prize_kits: [],
  };
}

export async function loadNewDemoTournament(): Promise<DemoTournamentSettingsData> {
  const response = await fetch(Routes.new_demo_form_tournaments_path(), {
    headers: { Accept: "application/json" },
    method: "GET",
  });
  if (!response.ok) {
    throw new Error(
      `HTTP ${response.status.toString()}: ${response.statusText}`,
    );
  }
  return (await response.json()) as DemoTournamentSettingsData;
}

export interface TournamentCreateResponse {
  id: number;
  name: string;
  url: string;
}

export interface TournamentCreateErrorResponse {
  errors: Errors;
}

export async function createDemoTournament(
  csrfToken: string,
  tournament: DemoTournamentSettings,
): Promise<TournamentCreateResponse> {
  const response = await fetch(Routes.create_demo_tournaments_path(), {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-CSRF-Token": csrfToken,
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
