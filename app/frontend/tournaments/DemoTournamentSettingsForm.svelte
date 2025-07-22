<script lang="ts">
  import {
    type Errors,
    type DemoTournamentSettings,
  } from "./DemoTournamentSettings";
  import FontAwesomeIcon from "../widgets/FontAwesomeIcon.svelte";
  export let tournament: DemoTournamentSettings = {};

  export let onSubmit = () => {
    console.log("Submitted: ", tournament);
  };
  export let submitLabel = "Save";
  export let submitIcon = "floppy-o";
  export let isSubmitting = false;
  export let errors: Errors = {};
</script>

<div class="form-group">
  <label for="name"><abbr title="required">*</abbr> Tournament name</label>
  <input
    type="text"
    id="name"
    class="form-control"
    bind:value={tournament.name}
  />
  {#if errors.name}
    <div class="invalid-feedback d-block">{errors.name}</div>
  {/if}
</div>

<div class="form-group">
  <label for="swiss_format">Swiss format</label>
  <select
    id="swiss_format"
    class="form-control"
    bind:value={tournament.swiss_format}
  >
    <option value="double_sided">Double-sided</option>
    <option value="single_sided">Single-sided</option>
  </select>
  {#if errors.swiss_format}
    <div class="invalid-feedback d-block">{errors.swiss_format}</div>
  {/if}
</div>

<div class="row">
  <div class="col-md-6">
    <div class="form-group">
      <label for="num_players">Number of Players</label>
      <input
    type="text"
    id="num_players"
    class="form-control"
    bind:value={tournament.num_players}
  />
      {#if errors.num_players}
        <div class="invalid-feedback d-block">{errors.num_players}</div>
      {/if}
    </div>
  </div>
  <div class="col-md-6">
    <div class="form-group">
      <label for="num_first_round_byes">Number of First Round Byes</label>
      <input
    type="text"
    id="num_first_round_byes"
    class="form-control"
    bind:value={tournament.num_first_round_byes}
  />
      {#if errors.num_first_round_byes}
        <div class="invalid-feedback d-block">{errors.num_first_round_byes}</div>
      {/if}
</div>
</div>
</div>

<div class="form-check mb-3">
  <input
    type="checkbox"
    id="assign_ids"
    class="form-check-input"
    bind:checked={tournament.assign_ids}
  />
  <label for="assign_ids" class="form-check-label">
    Assign random IDs for players?
  </label>
</div>

<div class="form-group">
  <button
    type="submit"
    class="btn btn-primary"
    on:click|preventDefault={onSubmit}
    disabled={isSubmitting}
  >
    <FontAwesomeIcon icon={submitIcon} />
    {#if isSubmitting}
      <span
        class="spinner-border spinner-border-sm"
        role="status"
        aria-hidden="true"
      ></span>
      Saving...
    {:else}
      {submitLabel}
    {/if}
  </button>
</div>
