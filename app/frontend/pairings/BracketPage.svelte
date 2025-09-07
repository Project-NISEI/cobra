<script lang="ts">
  import { onMount } from "svelte";
  import BracketDisplay from "./BracketDisplay.svelte";
  import type { PairingsData } from "./PairingsData";
  import { loadPairings } from "./PairingsData";
  import FontAwesomeIcon from "../widgets/FontAwesomeIcon.svelte";
  import { showIdentities } from "./ShowIdentities";

  export let tournamentId: number;
  let data: PairingsData;

  onMount(async () => {
    data = await loadPairings(tournamentId);
  });

  function toggleIdentities() {
    showIdentities.update((value) => !value);
  }
</script>

<div class="d-flex gap-2 align-items-center mb-2">
  <button class="btn btn-primary" on:click={toggleIdentities}>
    <FontAwesomeIcon icon="eye-slash" />
    Show/hide identities
  </button>
</div>

{#if data}
  {#each data.stages.filter((s) => s.is_elimination) as stage (stage.format)}
    <h4 class="mt-3 mb-2">{stage.name}</h4>
    <BracketDisplay {stage} />
  {/each}
  {#if data.stages.filter((s) => s.is_elimination).length === 0}
    <div class="alert alert-info">No elimination bracket available.</div>
  {/if}
{:else}
  <div class="d-flex align-items-center m-2">
    <div class="spinner-border m-auto"></div>
  </div>
{/if}
