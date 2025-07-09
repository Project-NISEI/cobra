<script lang="ts">
  import { onMount } from "svelte";
  import {
    createTournament,
    emptyTournamentOptions,
    type Errors,
    type FeatureFlags,
    loadNewTournament,
    type TournamentOptions,
    type TournamentSettings,
    ValidationError,
  } from "./TournamentSettings";
  import TournamentSettingsForm from "./TournamentSettingsForm.svelte";

  let tournament: TournamentSettings;
  let options: TournamentOptions = emptyTournamentOptions();
  let featureFlags: FeatureFlags = {};
  let csrfToken = "";

  let isSubmitting = false;
  let errors: Errors = {};

  onMount(async () => {
    // Fetch any initial data needed for the form (like available options)
    const data = await loadNewTournament();
    tournament = data.tournament;
    options = data.options;
    featureFlags = data.feature_flags;
    csrfToken = data.csrf_token;
  });

  async function submitNewTournament() {
    isSubmitting = true;
    errors = {};

    try {
      const response = await createTournament(csrfToken, tournament);
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
    <h1>Create a tournament</h1>

    {#if errors.base}
      <div class="alert alert-danger">{errors.base}</div>
    {:else if tournament}
      <form on:submit|preventDefault={submitNewTournament}>
        <TournamentSettingsForm
          {tournament}
          {options}
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
