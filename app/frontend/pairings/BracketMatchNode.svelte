<script lang="ts">
  import type { BracketMatch } from "./bracketTypes";
  import Identity from "../identities/Identity.svelte";
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

  function winnerIndex(match: BracketMatch): 1 | 2 | null {
    const side = parseWinnerSide(match.score_label);
    if (side) {
      if (match.player1?.side === side) return 1;
      if (match.player2?.side === side) return 2;
    }
    return null;
  }

  function getStyles(match: BracketMatch, playerIndex: 1 | 2): string {
    const wIdx = winnerIndex(match);
    const base = "flex-fill pr-2";
    if (wIdx === null) return base;
    return `${base} ${wIdx === playerIndex ? "winner" : "loser"}`;
  }

  function sideAbbrev(side: string | null | undefined): string | null {
    if (side === "corp") return "C";
    if (side === "runner") return "R";
    return null;
  }

  function labelFor(match: BracketMatch): string {
    return match.table_number != null
      ? String(match.table_number)
      : (match.table_label ?? "");
  }
</script>

<!-- eslint-disable-next-line @typescript-eslint/restrict-template-expressions -->
<g transform={`translate(${x}, ${y})`}>
  <rect {width} {height} rx="6" ry="6" fill="#fff" stroke="#ccc" />
  <text x="8" y={height / 2} class="game-label" dominant-baseline="middle"
    >{labelFor(match)}</text
  >
  <foreignObject x="28" y="2" width={width - 48} height={height - 4}>
    <div xmlns="http://www.w3.org/1999/xhtml" class="small content">
      <div class="player-line d-flex">
        <div class={getStyles(match, 1)}>
          {#if match.player1}
            {#if sideAbbrev(match.player1.side)}
              <span class="text-muted">
                {sideAbbrev(match.player1.side)}
              </span>
            {/if}
            <span class="truncate">{match.player1.name_with_pronouns}</span>
            {#if $showIdentities}
              <div class="ids">
                {#if match.player1.side === "corp" && match.player1.corp_id}
                  <Identity identity={match.player1.corp_id} />
                {:else if match.player1.side === "runner" && match.player1.runner_id}
                  <Identity identity={match.player1.runner_id} />
                {:else}
                  {#if match.player1.corp_id}
                    <Identity identity={match.player1.corp_id} />
                  {/if}
                  {#if match.player1.runner_id}
                    <Identity identity={match.player1.runner_id} />
                  {/if}
                {/if}
              </div>
            {/if}
          {:else}
            <em class="text-muted">TBD</em>
          {/if}
        </div>
      </div>
      <div class="player-line d-flex">
        <div class={getStyles(match, 2)}>
          {#if match.player2}
            {#if sideAbbrev(match.player2.side)}
              <span class="text-muted">
                {sideAbbrev(match.player2.side)}
              </span>
            {/if}
            <span class="truncate">{match.player2.name_with_pronouns}</span>
            {#if $showIdentities}
              <div class="ids">
                {#if match.player2.side === "corp" && match.player2.corp_id}
                  <Identity identity={match.player2.corp_id} />
                {:else if match.player2.side === "runner" && match.player2.runner_id}
                  <Identity identity={match.player2.runner_id} />
                {:else}
                  {#if match.player2.corp_id}
                    <Identity identity={match.player2.corp_id} />
                  {/if}
                  {#if match.player2.runner_id}
                    <Identity identity={match.player2.runner_id} />
                  {/if}
                {/if}
              </div>
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
