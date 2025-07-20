<script lang="ts">
  import { onMount } from "svelte";
  import {
    createDemoTournament,
    emptyDemoTournamentOptions,
    type Errors,
    type FeatureFlags,
    loadNewDemoTournament,
    type DemoTournamentOptions,
    type DemoTournamentSettings,
    ValidationError,
  } from "./DemoTournamentSettings";
  import DemoTournamentSettingsForm from "./DemoTournamentSettingsForm.svelte";

  let tournament: DemoTournamentSettings;
  let options: DemoTournamentOptions = emptyDemoTournamentOptions();
  let featureFlags: FeatureFlags = {};
  let csrfToken = "";

  let isSubmitting = false;
  let errors: Errors = {};

  onMount(async () => {
    // Fetch any initial data needed for the form (like available options)
    const data = await loadNewDemoTournament();
    tournament = data.tournament;
    options = data.options;
    featureFlags = data.feature_flags;
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
    <p>
      The description for the created tournament will contain a summary of your options.
    </p>

    {#if errors.base}
      <div class="alert alert-danger">{errors.base}</div>
    {:else if tournament}
      <form on:submit|preventDefault={submitNewTournament}>
        <DemoTournamentSettingsForm
          {tournament}
          {featureFlags}
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
