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
    <div class="col-sm-2 centre_score">
        {pairing.score_label}
        {#if pairing.intentional_draw}
            <span class="badge badge-pill badge-secondary score-badge">ID</span>
        {/if}
        {#if pairing.two_for_one}
            <span class="badge badge-pill badge-secondary score-badge">2 for 1</span>
        {/if}
    </div>
    <PlayerName player={pairing.player2} left_or_right="right"/>
</div>
