<script lang="ts">
  import type { Player } from "./PairingsData";
  import Identity from "../identities/Identity.svelte";
  import { showIdentities } from "./ShowIdentities";

  export let player: Player;
  export let self_report_label: string | null;
  export let left_or_right: string;
</script>

<div class="col-sm {left_or_right}_player_name">
  {player.name_with_pronouns}
  {#if player.side_label}
    {player.side_label}
  {/if}
  {#if self_report_label}
    (reported: {self_report_label})
  {/if}
  <div class="ids" style={$showIdentities ? "display: block;" : ""}>
    {#if player.side_label}
      <Identity
        identity={player.side == "corp" ? player.corp_id : player.runner_id}
      />
    {:else}
      <Identity identity={player.corp_id} />
      <Identity identity={player.runner_id} />
    {/if}
  </div>
</div>
