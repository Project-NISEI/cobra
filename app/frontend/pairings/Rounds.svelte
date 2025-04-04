<script lang="ts">
    import {onMount} from 'svelte';
    import Stage from "./Stage.svelte";
    import type {PairingsData} from "./PairingsData";
    import {loadPairings} from "./PairingsData";
    import FontAwesomeIcon from "../widgets/FontAwesomeIcon.svelte";
    import {showIdentities} from "./ShowIdentities"

    export let tournamentId: string;
    let data: PairingsData;

    onMount(async () => {
        data = await loadPairings(tournamentId);
    });

    function toggleIdentities() {
        showIdentities.update(value => !value);
    }
</script>

<button class="btn btn-primary" on:click={toggleIdentities}>
    <FontAwesomeIcon icon="eye-slash"/>
    Show/hide identities
</button>
<p></p>

{#if data}
    {#if data.is_player_meeting}
        <p>
            <a href="/tournaments/{tournamentId}/players/meeting" class="btn btn-primary">
                <FontAwesomeIcon icon="list-ul"/>
                Player meeting
            </a>
        </p>
    {/if}
    {#each data.stages as stage, index (stage.format)}
        <Stage stage={stage} start_expanded={index === data.stages.length - 1}/>
    {/each}
{:else}
    <div class="d-flex align-items-center m-2">
        <div class="spinner-border m-auto"></div>
    </div>
{/if}
