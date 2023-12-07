<script lang="ts">
    import Round from "./Round.svelte";

    export let tournament: any;
    export let stage: any;
</script>

<div class="accordion mb-3" role="tablist">
    <div class="row mb-1">
        <div class="col-sm-11">
            <h4>{stage.name}</h4>
        </div>
    </div>
    {#each stage.rounds as round}
        <Round tournament={tournament} stage={stage} round={round}/>
    {/each}
</div>
