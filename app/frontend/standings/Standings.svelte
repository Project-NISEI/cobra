<script lang="ts">
    import {onMount} from 'svelte';
    import DoubleElimStandings from "./DoubleElimStandings.svelte";
    import type {StandingsData} from "./StandingsData";
    import SwissStandings from "./SwissStandings.svelte";
    import {standings_data_tournament_players_path} from "../../assets/javascripts/routes";

    export let tournamentId: string;
    let data: StandingsData;

    onMount(async () => {
        const response = await fetch(
            standings_data_tournament_players_path(tournamentId),
            {
                method: 'GET',
            }
        );
        data = await response.json();
    });
</script>

<h2>Standings</h2>

{#if data}
    {#each data.stages as stage}
        {#if stage.format === 'double_elim' }
            <DoubleElimStandings stage={stage}/>
        {:else}
            <SwissStandings stage={stage} manual_seed="{data.manual_seed}"/>
        {/if}
    {/each}
{:else}
    <div class="d-flex align-items-center m-2">
        <div class="spinner-border m-auto"/>
    </div>
{/if}
