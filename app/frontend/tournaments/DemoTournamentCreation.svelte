<script lang="ts">
  import { onMount } from "svelte";
  import {
    createDemoTournament,
    type Errors,
    loadNewDemoTournament,
    type DemoTournamentSettings,
    ValidationError,
  } from "./DemoTournamentSettings";
  import DemoTournamentSettingsForm from "./DemoTournamentSettingsForm.svelte";

  let tournament: DemoTournamentSettings;
  let csrfToken = "";

  let isSubmitting = false;
  let errors: Errors = {};

  onMount(async () => {
    const data = await loadNewDemoTournament();
    tournament = data.tournament;
    csrfToken = data.csrf_token;
  });

  async function submitNewTournament() {
    isSubmitting = true;
    errors = {};

    try {
      const response = await createDemoTournament(csrfToken, tournament);
      window.location.href = response.url;
    } catch (error) {
      if (error instanceof ValidationError) {
        errors = error.errors;
      } else {
        errors = { base: ["An unexpected error occurred. Please try again."] };
      }
    } finally {
      isSubmitting = false;
    }
  }
</script>

<div class="row">
  <div class="col-12">
    <h1>Create a demo tournament</h1>
    <p>
      This allows you to create a private tournament with certain parameters, demo players with fake names, and specific rounds.
    </p>

    {#if errors.base}
      <div class="alert alert-danger">{errors.base}</div>
    {:else if tournament}
      <form on:submit|preventDefault={submitNewTournament}>
        <DemoTournamentSettingsForm
          {tournament}
          onSubmit={submitNewTournament}
          submitLabel="Create"
          submitIcon="plus"
          {isSubmitting}
          {errors}
        />
      </form>
    {:else}
      <div class="d-flex align-items-center m-2" data-testid="loading-spinner">
        <div class="spinner-border m-auto"></div>
      </div>
    {/if}
  </div>
</div>
