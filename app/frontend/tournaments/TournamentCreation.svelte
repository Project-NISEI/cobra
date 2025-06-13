<script lang="ts">
  import { onMount } from "svelte";
  import {
    emptyTournamentOptions,
    type Errors,
    loadNewTournament,
    type TournamentOptions,
    type TournamentSettings,
  } from "./TournamentSettings";
  import TournamentForm from "./TournamentForm.svelte";

  let tournament: TournamentSettings = {
    date: new Date().toISOString().split("T")[0], // Today's date as default
    time_zone: Intl.DateTimeFormat().resolvedOptions().timeZone, // Browser's timezone as default
    swiss_format: "double_sided",
  };
  let options: TournamentOptions = emptyTournamentOptions();

  let isSubmitting = false;
  let errors: Errors = {};
  let success = false;

  onMount(async () => {
    // Fetch any initial data needed for the form (like available options)
    const data = await loadNewTournament();
    // Merge any server-provided defaults with our local defaults
    tournament = { ...tournament, ...data.tournament };
  });

  function submitNewTournament() {
    isSubmitting = true;
    errors = {};
    console.log("Submitted: ", tournament);
  }
</script>

<div class="row">
  <div class="col-12">
    <h1>Create a tournament</h1>

    {#if success}
      <div class="alert alert-success">
        Tournament created successfully! Redirecting to tournament settings...
      </div>
    {:else if errors.base}
      <div class="alert alert-danger">{errors.base}</div>
    {/if}

    <form on:submit|preventDefault={submitNewTournament}>
      <TournamentForm
        {tournament}
        {options}
        onSubmit={submitNewTournament}
        submitLabel="Create"
        {isSubmitting}
        {errors}
      />
    </form>
  </div>
</div>
