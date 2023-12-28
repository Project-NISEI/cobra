<script lang="ts">
    import type {Identity} from "./Identity";

    export let identity: Identity | null;
    export let points: number | null = null;
</script>

{#if identity}
    <div class="{identity.faction}">
        <i class="fa icon icon-{identity.faction}"/>
        {#if identity.name}
            {identity.name}
        {/if}
        {#if points !== null}
            ({points})
        {/if}
    </div>
{/if}
