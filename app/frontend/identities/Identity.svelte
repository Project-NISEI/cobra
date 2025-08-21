<script lang="ts">
  import type { Identity } from "./Identity";

  export let identity: Identity | null;
  export let name_if_missing: string | null = null;
  export let points: number | null = null;

  export let include_icon: boolean = true;
  export let include_name: boolean = true;
  export let gray_out: boolean = false;
</script>

{#if identity && (identity.name || name_if_missing)}
  <div class={gray_out ? "" : identity.faction}>
    {#if include_icon}
      <i class="fa icon icon-{identity.faction}"></i>
    {/if}
    {#if include_name}
      {#if identity.name}
        {identity.name}
      {:else}
        {name_if_missing}
      {/if}
      {#if points !== null}
        ({points})
      {/if}
    {/if}
  </div>
{/if}
