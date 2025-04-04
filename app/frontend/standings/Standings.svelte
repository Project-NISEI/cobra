<script lang="ts">
    import {onMount} from 'svelte';
    import DoubleElimStandings from "./DoubleElimStandings.svelte";
    import type {CutStage, Stage, StandingsData, SwissStage} from "./StandingsData";
    import {loadStandings} from "./StandingsData";
    import SwissStandings from "./SwissStandings.svelte";

    export let tournamentId: string;
    let data: StandingsData;

    onMount(async () => {
        data = await loadStandings(tournamentId);
    });

    function cutStage(stage: Stage): CutStage {
        return stage as CutStage;
    }

    function swissStage(stage: Stage): SwissStage {
        return stage as SwissStage;
    }
</script>

<h2>Standings</h2>

{#if data}
    {#each data.stages as stage}
        {#if stage.format === 'single_elim' || stage.format === 'double_elim'}
            <DoubleElimStandings stage={cutStage(stage)}/>
        {:else}
            <SwissStandings stage={swissStage(stage)} manual_seed="{data.manual_seed}"/>
        {/if}
    {/each}
{:else}
    <div class="d-flex align-items-center m-2">
        <div class="spinner-border m-auto"></div>
    </div>
{/if}
