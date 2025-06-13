<script lang="ts">
  import { emptyTournamentOptions, type Errors, type TournamentOptions, type TournamentSettings } from "./TournamentSettings";
  export let tournament: TournamentSettings = {};
  export let options: TournamentOptions = emptyTournamentOptions();
  
  export let onSubmit = () => {
    console.log("Submitted: ", tournament);
  };
  export let submitLabel = 'Save';
  export let isSubmitting = false;
  export let errors: Errors = {};
</script>

<div class="form-group">
  <label for="name">Tournament name</label>
  <input 
    type="text" 
    id="name" 
    class="form-control" 
    bind:value={tournament.name} 
    required
  />
  {#if errors.name}
    <div class="invalid-feedback d-block">{errors.name}</div>
  {/if}
</div>

<div class="row">
  <div class="col-md-6">
    <div class="form-group">
      <label for="date">Date</label>
      <input 
        type="date" 
        id="date" 
        class="form-control" 
        bind:value={tournament.date}
      />
      {#if errors.date}
        <div class="invalid-feedback d-block">{errors.date}</div>
      {/if}
    </div>
  </div>
  <div class="col-md-6">
    <div class="form-group">
      <label for="time_zone">Time Zone</label>
      <select id="time_zone" class="form-control" bind:value={tournament.time_zone}>
        {#each options.time_zones as time_zone (time_zone.id)}
          <option value={time_zone.id}>{time_zone.name}</option>
        {/each}
      </select>
      {#if errors.time_zone}
        <div class="invalid-feedback d-block">{errors.time_zone}</div>
      {/if}
    </div>
  </div>
</div>

<div class="row">
  <div class="col-md-6">
    <div class="form-group">
      <label for="registration_starts">Registration Starts</label>
      <input 
        type="time" 
        id="registration_starts" 
        class="form-control" 
        bind:value={tournament.registration_starts}
      />
      {#if errors.registration_starts}
        <div class="invalid-feedback d-block">{errors.registration_starts}</div>
      {/if}
    </div>
  </div>
  <div class="col-md-6">
    <div class="form-group">
      <label for="tournament_starts">Tournament Starts</label>
      <input 
        type="time" 
        id="tournament_starts" 
        class="form-control" 
        bind:value={tournament.tournament_starts}
      />
      {#if errors.tournament_starts}
        <div class="invalid-feedback d-block">{errors.tournament_starts}</div>
      {/if}
    </div>
  </div>
</div>

<div class="form-group">
  <label for="swiss_format">Swiss Format</label>
  <select id="swiss_format" class="form-control" bind:value={tournament.swiss_format}>
    <option value="double_sided">Double-Sided</option>
    <option value="single_sided">Single-Sided</option>
  </select>
  {#if errors.swiss_format}
    <div class="invalid-feedback d-block">{errors.swiss_format}</div>
  {/if}
</div>

<div class="form-group">
  <label for="stream_url">Stream URL</label>
  <input 
    type="url" 
    id="stream_url" 
    class="form-control" 
    bind:value={tournament.stream_url}
  />
  {#if errors.stream_url}
    <div class="invalid-feedback d-block">{errors.stream_url}</div>
  {/if}
</div>

<div class="form-check mb-3">
  <input 
    type="checkbox" 
    id="self_registration" 
    class="form-check-input" 
    bind:checked={tournament.self_registration}
  />
  <label for="self_registration" class="form-check-label">
    Self-Registration: Allow players to use a link to register themselves
  </label>
</div>

<div class="form-check mb-3">
  <input 
    type="checkbox" 
    id="nrdb_deck_registration" 
    class="form-check-input" 
    bind:checked={tournament.nrdb_deck_registration}
  />
  <label for="nrdb_deck_registration" class="form-check-label">
    Deck registration: Upload decks from NetrunnerDB
  </label>
</div>

<div class="form-check mb-3">
  <input 
    type="checkbox" 
    id="allow_self_reporting" 
    class="form-check-input" 
    bind:checked={tournament.allow_self_reporting}
  />
  <label for="allow_self_reporting" class="form-check-label">
    Allow logged-in players to report their own match results
  </label>
</div>

<div class="form-check mb-3">
  <input 
    type="checkbox" 
    id="private" 
    class="form-check-input" 
    bind:checked={tournament.private}
  />
  <label for="private" class="form-check-label">
    Private: Only I will be able to view this tournament
  </label>
</div>

<div class="form-group">
  <button 
    type="submit" 
    class="btn btn-primary" 
    on:click|preventDefault={onSubmit} 
    disabled={isSubmitting}
  >
    {#if isSubmitting}
      <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>
      Saving...
    {:else}
      {submitLabel}
    {/if}
  </button>
</div>