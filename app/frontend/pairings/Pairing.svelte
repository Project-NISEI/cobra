<script lang="ts">
    import type {Pairing, Round, Stage} from "./PairingsData";
    import PlayerName from "./PlayerName.svelte";
    import FontAwesomeIcon from "../widgets/FontAwesomeIcon.svelte";

    export let stage: Stage;
    export let round: Round;
    export let pairing: Pairing;
    export let left_player = pairing.player1
    export let right_player = pairing.player2
    if (stage.format == 'single_sided_swiss' && pairing.player2.side_label == '(Corp)') {
        left_player = pairing.player2
        right_player = pairing.player1
    }
</script>

<div class="row m-1 round_pairing align-items-center table_{pairing.table_number}">
    <div class="col-sm-2">
        Table {pairing.table_number}
    </div>
    {#if pairing.policy.view_decks}
        <a href="{round.id}/pairings/{pairing.id}/view_decks">
            <FontAwesomeIcon icon="eye"/>
            View decks
        </a>
    {/if}
    <PlayerName player={left_player} left_or_right="left"/>
    <div class="col-sm-2 centre_score">
        {pairing.score_label}
        {#if pairing.intentional_draw}
            <span class="badge badge-pill badge-secondary score-badge">ID</span>
        {/if}
        {#if pairing.two_for_one}
            <span class="badge badge-pill badge-secondary score-badge">2 for 1</span>
        {/if}
    </div>
    <PlayerName player={right_player} left_or_right="right"/>
</div>
