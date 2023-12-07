<script lang="ts">
    import type {Player} from "./PairingsData";

    export let player: Player;
    export let left_or_right: string;
</script>
<div class="col-sm {left_or_right}_player_name">
    {player.name_with_pronouns}
    {#if player.side_label}
        {player.side_label}
    {/if}
</div>