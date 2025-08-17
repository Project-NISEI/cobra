<script lang="ts">
  import Round from "./Round.svelte";
  import type { Stage } from "./PairingsData";
  import BracketDisplay from "./BracketDisplay.svelte";

  export let stage: Stage;
  export let tournamentId: number;
  export let start_expanded: boolean;

  let showBracket = false;
  const isElim = ["double_elim", "single_elim"].includes(stage.format);
</script>

<div class="accordion mb-3" role="tablist">
  <div class="row mb-1">
    <div class="col-sm-11 d-flex align-items-baseline gap-2">
      <h4>{stage.name}</h4>
      {#if isElim}
        <button
          class="btn btn-link"
          on:click={() => (showBracket = !showBracket)}
        >
          {showBracket ? "Hide" : "Show"} Bracket
        </button>
      {/if}
    </div>
  </div>
  {#if showBracket && isElim}
    <BracketDisplay {stage} />
  {/if}
  {#each stage.rounds.filter((r) => r.id) as round, index (round.id)}
    <Round
      {tournamentId}
      {round}
      {stage}
      start_expanded={start_expanded && index === stage.rounds.length - 1}
    />
  {/each}
</div>
