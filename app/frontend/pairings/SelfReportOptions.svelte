<script lang="ts">
  import { type Pairing, type Round } from "./PairingsData";
  import { onMount } from "svelte";
  import { loadPresets, type PairingPreset, selfReport } from "./SelfReport";

  export let tournamentId: string;
  export let round: Round;
  export let pairing: Pairing;
  let presets: PairingPreset[];
  let csrfToken: string;

  onMount(async () => {
    const response = await loadPresets(
      tournamentId,
      round.id.toString(),
      pairing.id.toString(),
    );
    presets = response.presets;
    csrfToken = response.csrf_token;
  });

  async function onSelfReportClicked(data: PairingPreset) {
    const response = await selfReport(
      tournamentId,
      round.id.toString(),
      pairing.id.toString(),
      csrfToken,
      data,
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
        <p>Please click the button for the result to report this round</p>
        <div class="d-flex flex-row w-100 justify-content-around">
          {#each presets as preset, index (preset.label)}
            <button
              class="btn btn-primary"
              data-dismiss="modal"
              id="option-{index}"
              on:click={async () => {
                return onSelfReportClicked(preset);
              }}
            >
              {preset.label}
            </button>
          {/each}
        </div>
      </div>
    </div>
  </div>
</div>
