<script lang="ts">
    import type {Pairing} from "./PairingsData";
    import PlayerName from "./PlayerName.svelte";
    import FontAwesomeIcon from "../FontAwesomeIcon.svelte";

    export let pairing: Pairing;
</script>

<div class="row m-1 round_pairing align-items-center table_{pairing.table_number}">
    <div class="col-sm-2">
        Table {pairing.table_number}
    </div>
    {#if pairing.policy.view_decks}
        <a href="{pairing.round_id}/pairings/{pairing.id}/view_decks">
            <FontAwesomeIcon icon="eye"/>
            View decks
        </a>
    {/if}
    <PlayerName player={pairing.player1} left_or_right="left"/>
    <PlayerName player={pairing.player2} left_or_right="right"/>
</div>
