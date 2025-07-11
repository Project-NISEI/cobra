declare const Routes: {
  pairing_presets_tournament_round_pairing_path: (
    tournamentId: number,
    roundId: number,
    id: number,
  ) => string;
  self_report_tournament_round_pairing_path: (
    tournamentId: number,
    roundId: number,
    id: number,
  ) => string;
};

export async function loadPresets(
  tournamentId: number,
  roundId: number,
  pairingId: number,
): Promise<PairingPresetsData> {
  const response = await fetch(
    Routes.pairing_presets_tournament_round_pairing_path(
      tournamentId,
      roundId,
      pairingId,
    ),
    {
      method: "GET",
    },
  );
  return (await response.json()) as PairingPresetsData;
}

export async function selfReport(
  tournamentId: number,
  roundId: number,
  pairingId: number,
  csrfToken: string,
  data: PairingPreset,
): Promise<SelfReportResult> {
  const response = await fetch(
    Routes.self_report_tournament_round_pairing_path(
      tournamentId,
      roundId,
      pairingId,
    ),
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": csrfToken,
      },
      body: JSON.stringify({ pairing: data }),
    },
  );
  return (await response.json()) as SelfReportResult;
}

export interface PairingPreset {
  score1_corp: number;
  score2_corp: number;
  score1_runner: number;
  score2_runner: number;
  intentional_draw: boolean;
  label: string;
}

export interface PairingPresetsData {
  presets: PairingPreset[];
  csrf_token: string;
}

export type SelfReportResult =
  | { success: true }
  | { success: false; error: string };
