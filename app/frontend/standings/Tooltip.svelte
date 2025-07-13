<!-- TODO: Replace with library or move when used more often. Currently no need for a lib-->

<script>
  export let text = "";

  let isHovered = false;
</script>

<div
  class="position-relative"
  on:mouseenter={() => (isHovered = true)}
  on:mouseleave={() => (isHovered = false)}
>
  <slot />
  {#if isHovered}
    <div
      class="position-absolute bg-dark text-white p-1 rounded text-nowrap mb-1"
      style="bottom: 100%; left: 50%; transform: translateX(-50%); z-index: 1000;"
    >
      {text}
    </div>
  {/if}
</div>
