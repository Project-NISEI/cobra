<script lang="ts">
    import type {Identity} from "./Identity";

    export let identity: Identity | null;
</script>

{#if identity}
    <div class="{identity.faction}">
        <i class="fa icon icon-{identity.faction}"/>
        {identity.name}
    </div>
{/if}
