<script lang="ts">
    import type {Identity} from "./Identity";

    export let identity: Identity | null;
    export let name_if_missing: string | null = null;
    export let points: number | null = null;
</script>

{#if identity && (identity.name || name_if_missing)}
    <div class="{identity.faction}">
        <i class="fa icon icon-{identity.faction}"/>
        {#if identity.name}
            {identity.name}
        {:else}
            {name_if_missing}
        {/if}
        {#if points !== null}
            ({points})
        {/if}
    </div>
{/if}
