<script lang="ts">
    import Round from "./Round.svelte";
    import type {Stage} from "./pairings-data";

    export let stage: Stage;
    export let start_expanded: boolean;
</script>

<div class="accordion mb-3" role="tablist">
    <div class="row mb-1">
        <div class="col-sm-11">
            <h4>{stage.name}</h4>
        </div>
    </div>
    {#each stage.rounds as round, index}
        <Round round={round} start_expanded={start_expanded && index === stage.rounds.length - 1}/>
    {/each}
</div>
