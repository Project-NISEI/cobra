<script lang="ts">
  import { type Pairing, type Round, type Stage } from "./PairingsData";
  import PlayerName from "./PlayerName.svelte";
  import FontAwesomeIcon from "../widgets/FontAwesomeIcon.svelte";
  import SelfReportOptions from "./SelfReportOptions.svelte";

  export let tournamentId: number;
  export let stage: Stage;
  export let round: Round;
  export let pairing: Pairing;
  let left_player = pairing.player1;
  let right_player = pairing.player2;
  console.log(`Format: ${stage.format}`);
  if (pairing.player2.side == "corp" && stage.is_single_sided) {
    console.log(`Swapping players for round ${round.id.toString()}...`);
    left_player = pairing.player2;
    right_player = pairing.player1;
  }
</script>

<div
  class="row m-1 round_pairing align-items-center table_{pairing.table_number} {pairing
    .ui_metadata.row_highlighted
    ? 'current_user_row'
    : ''}"
>
  <div
    class="col-sm-2 {pairing.ui_metadata.row_highlighted
      ? 'font-weight-bold'
      : ''}"
  >
    {pairing.table_label}
  </div>
  {#if pairing.policy.view_decks}
    {#if stage.is_single_sided}
      <a href="{round.id}/pairings/{pairing.id}/view_decks">
        <FontAwesomeIcon icon="eye" />
        View decks
      </a>
    {:else}
      <a href="../players/{pairing.player1.id}/view_decks">
        <FontAwesomeIcon icon="eye" />
        View decks
      </a>
    {/if}
  {/if}
  <PlayerName player={left_player} left_or_right="left" />
  <div class="col-sm-2 centre_score">
    {pairing.score_label}
    {#if pairing.intentional_draw}
      <span class="badge badge-pill badge-secondary score-badge">ID</span>
    {/if}
    {#if pairing.two_for_one}
      <span class="badge badge-pill badge-secondary score-badge">2 for 1</span>
    {/if}
  </div>
  <PlayerName player={right_player} left_or_right="right" />
  {#if pairing.policy.view_decks && !stage.is_single_sided}
    <a href="../players/{pairing.player2.id}/view_decks">
      <FontAwesomeIcon icon="eye" />
      View decks
    </a>
  {/if}
  <div class="col-sm-2">
    {#if pairing.policy.self_report}
      <SelfReportOptions {tournamentId} {stage} {round} {pairing} />
    {/if}
    {#if pairing.self_report !== null}
      Report: {pairing.self_report.label}
    {/if}
  </div>
</div>
