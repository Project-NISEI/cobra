<script lang="ts">
  import {
    type Pairing,
    type Player,
    type Round,
    type Stage,
  } from "./PairingsData";
  import PlayerName from "./PlayerName.svelte";
  import FontAwesomeIcon from "../widgets/FontAwesomeIcon.svelte";
  import SelfReportOptions from "@/pairings/SelfReportOptions.svelte";

  export let tournamentId: string;
  export let stage: Stage;
  export let round: Round;
  export let pairing: Pairing;
  let left_player = pairing.player1;
  let right_player = pairing.player2;
  console.log(`Format: ${stage.format}`);
  if (
    pairing.player2.side == "corp" &&
    ["single_sided_swiss", "double_elim", "single_elim"].includes(stage.format)
  ) {
    console.log(`Swapping players for round ${round.id.toString()}...`);
    left_player = pairing.player2;
    right_player = pairing.player1;
  }

  function selfReportLable(pairing: Pairing, player: Player) {
    if (pairing.self_report?.report_player_id !== player.user_id) {
      return null;
    }
    return pairing.self_report.label;
  }
</script>

<div
  class="row m-1 round_pairing align-items-center table_{pairing.table_number}"
>
  <div class="col-sm-2">
    {pairing.table_label}
  </div>
  {#if pairing.policy.view_decks}
    <a href="{round.id}/pairings/{pairing.id}/view_decks">
      <FontAwesomeIcon icon="eye" />
      View decks
    </a>
  {/if}
  <PlayerName
    player={left_player}
    left_or_right="left"
    self_report_label={selfReportLable(pairing, left_player)}
  />
  <div class="col-sm-2 centre_score">
    {pairing.score_label}
    {#if pairing.intentional_draw}
      <span class="badge badge-pill badge-secondary score-badge">ID</span>
    {/if}
    {#if pairing.two_for_one}
      <span class="badge badge-pill badge-secondary score-badge">2 for 1</span>
    {/if}
  </div>
  <PlayerName
    player={right_player}
    left_or_right="right"
    self_report_label={selfReportLable(pairing, right_player)}
  />
  <div class="col-sm-2">
    {#if pairing.policy.self_report}
      <SelfReportOptions {tournamentId} {round} {pairing} />
    {/if}
  </div>
</div>
