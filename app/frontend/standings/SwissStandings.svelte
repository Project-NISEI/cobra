<script lang="ts">
  import type { SwissStage } from "./StandingsData";
  import Identity from "../identities/Identity.svelte";
  import FontAwesomeIcon from "../widgets/FontAwesomeIcon.svelte";
  import Tooltip from "./Tooltip.svelte";

  export let stage: SwissStage;
  export let manual_seed: boolean;

  function printSideBias(sideBias: number | null) {
    if (sideBias == null || sideBias === 0) {
      return "Balanced";
    } else if (sideBias > 0) {
      return `Corp +${String(sideBias)}`;
    } else {
      return `Runner +${String(-sideBias)}`;
    }
  }

  function printSOS(sos: string) {
    return parseFloat(sos).toLocaleString(undefined, {
      minimumFractionDigits: 4,
      maximumFractionDigits: 4,
    });
  }
</script>

<p>After {stage.rounds_complete} rounds</p>

<table class="table table-striped standings">
  <thead>
    <tr>
      <th>Rank</th>
      <th>Name</th>
      {#if stage.any_decks_viewable}
        <th>Decks</th>
      {/if}
      <th>IDs</th>
      <th>Points</th>
      {#if manual_seed}
        <th>Seed</th>
      {/if}
      <th>SoS</th>
      <th>ESoS</th>
      {#if stage.format === "single_sided_swiss"}
        <th>Side Bias</th>
      {/if}
    </tr>
  </thead>
  <tbody>
    {#each stage.standings as standing (standing.position)}
      <tr>
        <td>{standing.position}</td>
        <td class="d-flex flex-row space-x-2">
          <p class="mr-2">{standing.player.name_with_pronouns}</p>
          {#if !standing.player.active}
            <Tooltip text="(dropped)">
              <FontAwesomeIcon icon="sign-out" />
            </Tooltip>
          {/if}
        </td>
        {#if stage.any_decks_viewable}
          <td>
            {#if standing.policy.view_decks}
              <a href="{standing.player.id}/view_decks">
                <FontAwesomeIcon icon="eye" />
                View decks
              </a>
            {/if}
          </td>
        {/if}
        <td class="ids">
          <Identity
            identity={standing.player.corp_id}
            points={standing.corp_points}
            name_if_missing="Corp"
          />
          <Identity
            identity={standing.player.runner_id}
            points={standing.runner_points}
            name_if_missing="Runner"
          />
          {#if standing.bye_points > 0}
            &nbsp;Bye ({standing.bye_points})
          {/if}
        </td>
        <td>
          {standing.points}
        </td>
        {#if manual_seed}
          <td>{standing.manual_seed}</td>
        {/if}
        <td>{printSOS(standing.sos)}</td>
        <td>{printSOS(standing.extended_sos)}</td>
        {#if stage.format === "single_sided_swiss"}
          <td>{printSideBias(standing.side_bias)}</td>
        {/if}
      </tr>
    {/each}
  </tbody>
</table>
