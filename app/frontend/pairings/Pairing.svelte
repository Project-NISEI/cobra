<script lang="ts">
    import type {Pairing} from "./pairings-data";

    export let pairing: Pairing;
</script>

<div class="row m-1 round_pairing align-items-center table_{pairing.table_number}">
    <div class="col-sm-2">
        Table {pairing.table_number}
    </div>
    {#if pairing.policy.view_decks}
        <a href="{pairing.round_id}/pairings/{pairing.id}/view_decks">
            <i class="fa fa-eye"/>
            View decks
        </a>
    {/if}
    <div class="col-sm left_player_name">
        {pairing.player1.name_with_pronouns}
    </div>
    <div class="col-sm right_player_name">
        {pairing.player2.name_with_pronouns}
    </div>
</div>
