<script lang="ts">
    import {onMount} from 'svelte';

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
    <div class="accordion mb-3" role="tablist">
        <div class="row mb-1">
            <div class="col-sm-11">
                <h4>{stage.name}</h4>
            </div>
        </div>
        {#each stage.rounds as round}
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
                <div class="collapse{round.details.id === data.stages.at(-1).rounds.at(-1).details.id ? ' show' : ''}"
                     id="round{round.details.id}">
                    <div class="col-12 my-3">
                        <a class="btn btn-primary"
                           href="tournaments/{tournamentId}/rounds/{round.details.id}/pairings">
                            <i class="fa fa-list-ul"/>
                            Pairings by name
                        </a>
                        {#each round.pairings as pairing}
                            <div class="row m-1 round_pairing align-items-center table_{pairing.details.table_number}">
                                <div class="col-sm-2">
                                    Table {pairing.details.table_number}
                                </div>
                                {#if stage.policy.view_decks}
                                    <a href="tournaments/{tournamentId}/rounds/{round.details.id}/pairings/{pairing.details.id}">
                                        <i class="fa fa-eye"/>
                                        View decks
                                    </a>
                                {/if}
                                <div class="col-sm left_player_name">
                                    {pairing.player1.name}{pairing.player1.pronouns ? ' (' + pairing.player1.pronouns + ')' : ''}
                                </div>
                                <div class="col-sm right_player_name">
                                    {pairing.player2.name}{pairing.player2.pronouns ? ' (' + pairing.player2.pronouns + ')' : ''}
                                </div>
                            </div>
                        {/each}
                    </div>
                </div>
            </div>
        {/each}
    </div>
{/each}
