<script lang="ts">
  import type { BracketMatch, BracketPlayer } from "./bracketTypes";
  import type { Identity } from "../identities/Identity";
  import IdentityComponent from "../identities/Identity.svelte";
  import { showIdentities } from "./ShowIdentities";

  export let match: BracketMatch;
  export let x: number;
  export let y: number;
  export let width: number;
  export let height: number;

  function parseWinnerSide(
    scoreLabel: string | null | undefined,
  ): "corp" | "runner" | null {
    if (!scoreLabel) return null;
    const res = /\((C|R)\)/.exec(scoreLabel);
    if (!res) return null;
    return res[1] === "C" ? "corp" : "runner";
  }

  function hasWinner(match: BracketMatch): boolean {
    return !!match.score_label?.includes("R") || !!match.score_label?.includes("C");
  }

  function isWinner(player: BracketPlayer | undefined | null): boolean {
    if (!player) return false;
    if (!hasWinner(match)) return false;
    const winnerSide = parseWinnerSide(match.score_label);
    return winnerSide === player.side;
  }

  function isLoser(player: BracketPlayer | undefined | null): boolean {
    if (!player) return false;
    if (!hasWinner(match)) return false;
    const winnerSide = parseWinnerSide(match.score_label);
    return winnerSide !== player.side;
  }

  function labelFor(match: BracketMatch): string {
    return match.table_number != null
      ? String(match.table_number)
      : (match.table_label ?? "");
  }

  function getIdentity(player: BracketPlayer): Identity | undefined | null {
    if (player.side === "corp") {
      return player.corp_id;
    } else if (player.side === "runner") {
      return player.runner_id;
    }
    return null;
  }


  $: topPlayer = match.player1?.side === "corp" ? match.player1 : match.player2;
  $: bottomPlayer =
    match.player1?.side === "corp" ? match.player2 : match.player1;
</script>


<g transform={`translate(${x}, ${y})`}>
  <rect {width} {height} rx="6" ry="6" fill="#fff" stroke="#ccc" />
  <text x="8" y={height / 2} class="game-label" dominant-baseline="middle"
    >{labelFor(match)}</text
  >
  <foreignObject x="28" y="2" width={width - 40} height={height - 4}>
    <div xmlns="http://www.w3.org/1999/xhtml" class="small content">
      <div class="player-line d-flex" class:mb-1={$showIdentities}>
        <div
          class="flex-fill pr-2 {match.score_label
            ? !hasWinner(match) ? '' : isWinner(topPlayer) ? 'winner' : 'loser'
            : ''}"
        >
      {#if topPlayer}
            {@const identity = getIdentity(topPlayer)}
            <div class="player-info">
              {#if identity}
                <IdentityComponent {identity} include_name={false} gray_out={isLoser(topPlayer)} />
              {/if}
              <span class="truncate">
                {topPlayer.name_with_pronouns}
              </span>
            </div>
            {#if $showIdentities}
              {#if identity}
                <div class="ids">
                  <IdentityComponent {identity} include_icon={false} gray_out={isLoser(topPlayer)} />
                </div>
              {/if}
            {/if}
          {:else}
            <em class="text-muted">TBD</em>
          {/if}
        </div>
      </div>
      <div class="player-line d-flex">
        <div
          class="flex-fill pr-2 {match.score_label
            ? !hasWinner(match) ? '' : isWinner(bottomPlayer) ? 'winner' : 'loser'
            : ''}"
        >
          {#if bottomPlayer}
            {@const identity = getIdentity(bottomPlayer)}
            <div class="player-info">
              {#if identity}
                <IdentityComponent {identity} include_name={false} gray_out={isLoser(bottomPlayer)} />
              {/if}
              <span class="truncate">
                {bottomPlayer.name_with_pronouns}
              </span>
            </div>
            {#if $showIdentities}
              {#if identity}
                <div class="ids">
                  <IdentityComponent {identity} include_icon={false} gray_out={isLoser(bottomPlayer)} />
                </div>
              {/if}
            {/if}
          {:else}
            <em class="text-muted">TBD</em>
          {/if}
        </div>
      </div>
    </div>
  </foreignObject>
</g>

<style>
  .small {
    font-size: 0.85rem;
    line-height: 1.1rem;
  }
  .content {
    height: 100%;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }
  .winner {
    font-weight: 600;
    color: #212529;
  }
  .loser {
    color: #6c757d;
  }
  .player-line {
    white-space: nowrap;
    overflow: visible;
  }
  .player-info {
    display: flex;
    align-items: center;
    gap: 4px;
  }
  .truncate {
    display: inline-block;
    max-width: 100%;
    vertical-align: bottom;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .game-label {
    font-size: 0.75rem;
    fill: #6c757d;
    font-weight: 500;
  }
  .ids {
    font-size: 0.7rem;
    white-space: nowrap;
    overflow-x: hidden;
    overflow-y: visible;
    line-height: 1.2;
    margin-top: 2px;
  }
</style>
