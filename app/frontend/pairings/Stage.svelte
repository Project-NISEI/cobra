<script lang="ts">
  import type { Stage } from "./PairingsData.ts";
  import Round from "./Round.svelte";
  import BracketDialog from "./BracketDialog.svelte";
  let dialog: HTMLDialogElement;

  export let stage: Stage;
  export let tournamentId: number;
  export let start_expanded: boolean;
</script>

<div class="accordion mb-3" role="tablist">
  <div class="row mb-1">
    <div class="col-sm-11">
      <h4 class="d-inline">{stage.name}</h4>
      svelte
      {#if ["double_elim", "single_elim"].includes(stage.format)}
        <button class="btn btn-link" on:click={() => dialog.showModal()}
          >View Bracket</button
        >
      {/if}
    </div>
  </div>
  {#each stage.rounds.filter((r) => r.id) as round, index (round.id)}
    <Round
      {tournamentId}
      {round}
      {stage}
      start_expanded={start_expanded && index === stage.rounds.length - 1}
    />
  {/each}
</div>

<BracketDialog bind:dialog {stage}></BracketDialog>
