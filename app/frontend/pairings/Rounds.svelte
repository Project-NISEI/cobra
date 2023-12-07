<script lang="ts">
    import {onMount} from 'svelte';
    import Stage from "./Stage.svelte";

    export let tournamentId: String;
    let data: any;

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

{#each data ? data.stages : [] as stage}
    <Stage tournament={data} stage={stage}/>
{/each}
