<script lang="ts">
    import {onMount} from 'svelte';
    import Stage from "./Stage.svelte";
    import type {PairingsData} from "./PairingsData";
    import FontAwesomeIcon from "../widgets/FontAwesomeIcon.svelte";
    import {showIdentities} from "./ShowIdentities"

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

    function toggleIdentities() {
        showIdentities.update(value => !value);
    }
</script>

<button id="toggle_identities" class="btn btn-primary" on:click={toggleIdentities}>
    <FontAwesomeIcon icon="eye-slash"/>
    Show/hide identities
</button>
<p/>

{#if data}
    {#if data.is_player_meeting}
        <p>
            <a href="/tournaments/{tournamentId}/players/meeting" class="btn btn-primary">
                <FontAwesomeIcon icon="list-ul"/>
                Player meeting
            </a>
        </p>
    {/if}
    {#each data.stages as stage, index}
        <Stage stage={stage} start_expanded={index === data.stages.length - 1}/>
    {/each}
{:else}
    <div class="d-flex align-items-center m-2">
        <div class="spinner-border m-auto"/>
    </div>
{/if}
