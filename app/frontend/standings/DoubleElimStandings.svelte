<script lang="ts">
    import type {Stage} from "./StandingsData";
    import Identity from "../identities/Identity.svelte";

    export let stage: Stage;
</script>

<table class="table table-striped standings">
    <thead>
    <tr>
        <th>Rank</th>
        <th>Name</th>
        {#if stage.policy.view_decks}
            <th>Decks</th>
        {/if}
        <th>IDs</th>
        <th>Seed</th>
    </tr>
    </thead>
    <tbody>
    {#each stage.standings as standing, index}
        <tr>
            <td>{index + 1}</td>
            {#if standing.player}
                <td>{standing.player.name_with_pronouns}</td>
                {#if stage.policy.view_decks}
                    <th>???</th>
                {/if}
                <td class="ids">
                    <Identity identity={standing.player.corp_id}/>
                    <Identity identity={standing.player.runner_id}/>
                </td>
                <td>{standing.seed}</td>
            {:else}
                <td>???</td>
                {#if stage.policy.view_decks}
                    <th>???</th>
                {/if}
                <td class="ids">
                    <p>???</p>
                    <p>???</p>
                </td>
                <td>???</td>
            {/if}
        </tr>
    {/each}
    </tbody>
</table>
