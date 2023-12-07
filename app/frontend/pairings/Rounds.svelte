<script lang="ts">
    import {onMount} from 'svelte';
    import Stage from "./Stage.svelte";
    import type {PairingsData} from "./pairings-data";

    export let tournamentId: String;
    let data: PairingsData;

    onMount(async () => {
        const response = await fetch(
            '/tournaments/' + tournamentId + "/rounds/pairings_data",
            {
                method: 'GET',
            }
        );
        data = await response.json();
        console.log(data);
    });
</script>

{#each data ? data.stages : [] as stage, index}
    <Stage stage={stage} start_expanded={index === data.stages.length - 1}/>
{/each}
