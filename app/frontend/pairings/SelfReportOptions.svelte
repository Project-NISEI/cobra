<script lang="ts">
  import {
    type Pairing,
    type Player,
    type Round,
    type Stage,
  } from "./PairingsData";
  import { onMount } from "svelte";
  import {
    loadPresets,
    type SelfReportPresets,
    selfReport,
  } from "./SelfReport";

  export let tournamentId: number;
  export let stage: Stage;
  export let round: Round;
  export let pairing: Pairing;
  let presets: SelfReportPresets[];
  let csrfToken: string;

  let customReporting = false;

  let score1: number;
  let score2: number;

  let left_player_number = 1;
  let left_player: Player;
  let right_player: Player;

  left_player = pairing.player1;
  right_player = pairing.player2;
  if (
    stage.format === "single_sided_swiss" ||
    stage.format === "double_elim" ||
    stage.format === "single_elim"
  ) {
    if (pairing.player1.side === "runner") {
      left_player_number = 2;
      left_player = pairing.player2;
      right_player = pairing.player1;
    }
  }

  onMount(async () => {
    const response = await loadPresets(tournamentId, round.id, pairing.id);
    presets = response.presets;
    csrfToken = response.csrf_token;
  });

  function onCustomReportClicked() {
    customReporting = !customReporting;
  }

  async function onSelfReportPresetClicked(data: SelfReportPresets) {
    const response = await selfReport(
      tournamentId,
      round.id,
      pairing.id,
      csrfToken,
      { score1: null, score2: null, ...data },
    );
    if (!response.success) {
      alert(response.error);
      return;
    }
    // TODO: instead of reloading, maybe use result value
    window.location.reload();
  }

  async function onCustomSelfReportSubmit(score1: number, score2: number) {
    const response = await selfReport(
      tournamentId,
      round.id,
      pairing.id,
      csrfToken,
      {
        score1,
        score2,
        intentional_draw: false,
        score1_corp: null,
        score1_runner: null,
        score2_corp: null,
        score2_runner: null,
      },
    );
    if (!response.success) {
      alert(response.error);
      return;
    }
    // TODO: instead of reloading, maybe use result value
    window.location.reload();
  }
</script>

<button
  type="button"
  class="btn btn-primary"
  data-toggle="modal"
  data-target="#reportModal"
>
  Report Pairing
</button>

<div
  class="modal fade"
  id="reportModal"
  tabindex="-1"
  role="dialog"
  aria-labelledby="reportModal"
  aria-hidden="true"
>
  <div class="modal-dialog modal-dialog-centered" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h4 class="modal-title" id="reportModal">Report Pairing</h4>
        <button
          type="button"
          class="close"
          data-dismiss="modal"
          aria-label="Close"
        >
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body">
        <p>Please click the button for the result to report this pairing:</p>
        <p>
          {left_player.name_with_pronouns} vs. {right_player.name_with_pronouns}
        </p>
        <div
          style="gap: 20px;"
          class="d-flex flex-row w-100 justify-content-center"
        >
          {#if !customReporting}
            {#each presets as preset, index (preset.label)}
              <button
                class="btn btn-primary"
                data-dismiss="modal"
                id="option-{index}"
                on:click={async () => {
                  return onSelfReportPresetClicked(preset);
                }}
              >
                {preset.extra_self_report_label ?? preset.label}
              </button>
            {/each}
          {:else}
            {#if left_player_number === 1}
              <input
                type="text"
                id="name"
                style="width: 2.5em;"
                class="form-control"
                bind:value={score1}
              />
              <p>-</p>
              <input
                type="text"
                id="name"
                style="width: 2.5em;"
                class="form-control"
                bind:value={score2}
              />
            {:else}
              <input
                type="text"
                id="name"
                style="width: 2.5em;"
                class="form-control"
                bind:value={score2}
              />
              <p>-</p>
              <input
                type="text"
                id="name"
                style="width: 2.5em;"
                class="form-control"
                bind:value={score1}
              />
            {/if}
            <button
              class="btn btn-primary"
              data-dismiss="modal"
              id="option-custom"
              on:click={async () => {
                return onCustomSelfReportSubmit(score1, score2);
              }}
            >
              Submit
            </button>
          {/if}
          <button
            class="btn btn-primary"
            id="option-custom"
            on:click={() => {
              onCustomReportClicked();
            }}
          >
            {customReporting ? "Presets" : "Custom"}
          </button>
        </div>
      </div>
    </div>
  </div>
</div>
