<script lang="ts">
  import { type Pairing, type Round, type Stage } from "./PairingsData";
  import PlayerName from "./PlayerName.svelte";
  import FontAwesomeIcon from "../widgets/FontAwesomeIcon.svelte";
  import { onMount } from "svelte";
  import { loadPresets, type PairingPreset, selfReport } from "./SelfReport";

  export let tournamentId: string;
  export let stage: Stage;
  export let round: Round;
  export let pairing: Pairing;
  let left_player = pairing.player1;
  let right_player = pairing.player2;
  let presets: PairingPreset[];
  let csrfToken: string;
  console.log(`Format: ${stage.format}`);
  if (
    pairing.player2.side == "corp" &&
    ["single_sided_swiss", "double_elim", "single_elim"].includes(stage.format)
  ) {
    console.log(`Swapping players for round ${round.id.toString()}...`);
    left_player = pairing.player2;
    right_player = pairing.player1;
  }

  onMount(async () => {
    const response = await loadPresets(
      tournamentId,
      round.id.toString(),
      pairing.id.toString(),
    );
    presets = response.presets;
    csrfToken = response.csrf_token;
  });

  async function toggleIdentities(data: PairingPreset) {
    await selfReport(
      tournamentId,
      round.id.toString(),
      pairing.id.toString(),
      csrfToken,
      data,
    );
  }
</script>

<div
  class="row m-1 round_pairing align-items-center table_{pairing.table_number}"
>
  <div class="col-sm-2">
    {pairing.table_label}
  </div>
  {#if pairing.policy.view_decks}
    <a href="{round.id}/pairings/{pairing.id}/view_decks">
      <FontAwesomeIcon icon="eye" />
      View decks
    </a>
  {/if}
  <PlayerName
    player={left_player}
    left_or_right="left"
    self_reported={pairing.self_report?.report_player_id ===
      left_player.user_id}
  />
  <div class="col-sm-2 centre_score">
    {pairing.score_label}
    {#if pairing.intentional_draw}
      <span class="badge badge-pill badge-secondary score-badge">ID</span>
    {/if}
    {#if pairing.two_for_one}
      <span class="badge badge-pill badge-secondary score-badge">2 for 1</span>
    {/if}
  </div>
  <PlayerName
    player={right_player}
    left_or_right="right"
    self_reported={pairing.self_report?.report_player_id ===
      right_player.user_id}
  />
  {#if pairing.policy.self_report}
    <div class="m-1">
      {#each presets as preset, index (preset.label)}
        <button
          class="btn btn-primary mr-1"
          id="option-{index}"
          on:click={async () => {
            return toggleIdentities(preset);
          }}
        >
          {preset.label}
        </button>
      {/each}
    </div>
  {/if}
</div>
