<script lang="ts">
    import {onMount} from 'svelte';
    import Stage from "./Stage.svelte";
    import type {PairingsData} from "./PairingsData";
    import FontAwesomeIcon from "../FontAwesomeIcon.svelte";

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
    });
</script>

<div id="toggle_identities" class="btn btn-primary">
    <FontAwesomeIcon icon="eye-slash"/>
    Show/hide identities
</div>
<p/>

{#each data ? data.stages : [] as stage, index}
    <Stage stage={stage} start_expanded={index === data.stages.length - 1}/>
{/each}
