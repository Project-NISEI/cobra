<script lang="ts">
  import type { Stage } from "./PairingsData.ts";
  import PlayerName from "./PlayerName.svelte";

  export let dialog: HTMLDialogElement;
  export let stage: Stage;

  // function drawLines(node: HTMLDialogElement) {

  // }
</script>

<!-- use:drawLines -->
<dialog bind:this={dialog}>
  <canvas class="position-absolute"></canvas>

  <h3>Upper Bracket</h3>
  <div class="d-flex flex-row mb-3">
    {#each stage.rounds as round}
      <div class="d-flex flex-column justify-content-center mr-3">
        <h4>Round {round.number}</h4>
        {#each round.pairings as pairing}
          {#if pairing.bracket_type == "upper"}
            <div class="my-auto pb-3">
              {pairing.table_label} (next: {pairing.successor_game})
              {#if pairing.id}
                <div class="border">
                  <PlayerName player={pairing.player1} left_or_right="left" />
                </div>
                <div class="border">
                  <PlayerName player={pairing.player2} left_or_right="left" />
                </div>
              {:else}
                <div class="border">Not paired</div>
              {/if}
            </div>
          {/if}
        {/each}
      </div>
    {/each}
  </div>

  <h3>Lower Bracket</h3>
  <div class="d-flex flex-row mb-3">
    {#each stage.rounds.filter((r) => r.pairings.filter((p) => p.bracket_type == "lower").length > 0) as round}
      <div class="d-flex flex-column justify-content-center mr-3">
        <h4>Round {round.number}</h4>
        {#each round.pairings as pairing}
          {#if pairing.bracket_type == "lower"}
            <div class="my-auto pb-3">
              {pairing.table_label} (next: {pairing.successor_game})
              {#if pairing.id}
                <div class="border">
                  <PlayerName player={pairing.player1} left_or_right="left" />
                </div>
                <div class="border">
                  <PlayerName player={pairing.player2} left_or_right="left" />
                </div>
              {:else}
                <div class="border">Not paired</div>
              {/if}
            </div>
          {/if}
        {/each}
      </div>
    {/each}
  </div>

  <div>
    <button
      class="btn btn-secondary float-right"
      on:click={() => dialog.close()}>Close</button
    >
  </div>
</dialog>
