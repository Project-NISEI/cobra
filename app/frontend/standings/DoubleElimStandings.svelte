<script lang="ts">
    import type {CutStage} from "./StandingsData";
    import Identity from "../identities/Identity.svelte";
    import FontAwesomeIcon from "@/widgets/FontAwesomeIcon.svelte";

    export let stage: CutStage;
</script>

<table class="table table-striped standings">
    <thead>
    <tr>
        <th>Rank</th>
        <th>Name</th>
        {#if stage.any_decks_viewable}
            <th>Decks</th>
        {/if}
        <th>IDs</th>
        <th>Seed</th>
    </tr>
    </thead>
    <tbody>
    {#each stage.standings as standing}
        <tr>
            <td>{standing.position}</td>
            {#if standing.player}
                <td>{standing.player.name_with_pronouns}</td>
                {#if standing.policy.view_decks}
                    <td>
                        <a href="{standing.player.id}/view_decks">
                            <FontAwesomeIcon icon="eye"/>
                            View decks
                        </a>
                    </td>
                {:else if stage.any_decks_viewable}
                    <td/>
                {/if}
                <td class="ids">
                    <Identity identity={standing.player.corp_id}/>
                    <Identity identity={standing.player.runner_id}/>
                </td>
                <td>{standing.seed}</td>
            {:else}
                <td>???</td>
                {#if standing.policy.view_decks}
                    <td>???</td>
                {:else if stage.any_decks_viewable}
                    <td/>
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
