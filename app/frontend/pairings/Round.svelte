<script lang="ts">
    import type {Round} from "./pairings-data";
    import Pairing from "./Pairing.svelte";

    export let round: Round;
    export let start_expanded: boolean;
</script>

<div class="card">
    <div class="card-header" role="tab">
        <div class="row">
            <div class="col-sm-9">
                <a data-toggle="collapse" href="#round{round.details.id}">
                    <h5 class="mb-0">Round {round.details.number}</h5>
                </a>
            </div>
            <div class="col-sm-3">
                {round.pairings_reported} / {round.pairings.length} pairings reported
            </div>
        </div>
    </div>
    <div class="collapse{start_expanded ? ' show' : ''}"
         id="round{round.details.id}">
        <div class="col-12 my-3">
            <a class="btn btn-primary" href="{round.details.id}/pairings">
                <i class="fa fa-list-ul"/>
                Pairings by name
            </a>
            {#each round.pairings as pairing}
                <Pairing pairing={pairing}/>
            {/each}
        </div>
    </div>
</div>
