<script lang="ts">
  import {
    type Pairing,
    type Player,
    type Round,
    type Stage,
  } from "./PairingsData";
  import PlayerName from "./PlayerName.svelte";
  import FontAwesomeIcon from "../widgets/FontAwesomeIcon.svelte";
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
    await selfReport(
      tournamentId,
      round.id.toString(),
      pairing.id.toString(),
      csrfToken,
      data,
    );
  }
</script>

<!--<div class="dropdown">-->
<!--  <button class="btn btn-secondary dropdown-toggle" data-toggle="dropdown" data-boundary="viewport">-->
<!--    Self Report-->
<!--  </button>-->
<!--    <div class="dropdown-menu ">-->
<!--      {#each presets as preset, index (preset.label)}-->
<!--        <button-->
<!--          class="dropdown-item"-->
<!--          id="option-{index}"-->
<!--          on:click={async () => {-->
<!--            return onSelfReportClicked(preset);-->
<!--          }}-->
<!--        >-->
<!--          {preset.label}-->
<!--        </button>-->
<!--      {/each}-->
<!--    </div>-->
<!--</div>-->

<button
  type="button"
  class="btn btn-primary"
  data-toggle="modal"
  data-target="#exampleModal"
>
  Report Game
</button>

<!-- Modal -->
<div
  class="modal fade"
  id="exampleModal"
  tabindex="-1"
  role="dialog"
  aria-labelledby="exampleModalLabel"
  aria-hidden="true"
>
  <div class="modal-dialog modal-dialog-centered" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h2 class="modal-title" id="exampleModalLabel">Report Game</h2>
      </div>
      <div class="modal-body">
        {#each presets as preset, index (preset.label)}
          <button
            class="btn btn-primary"
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
