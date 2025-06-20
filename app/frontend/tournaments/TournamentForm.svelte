<script lang="ts">
  import {
    emptyTournamentOptions,
    type Errors,
    type FeatureFlags,
    type TournamentOptions,
    type TournamentSettings,
  } from "./TournamentSettings";
  export let tournament: TournamentSettings = {};
  export let options: TournamentOptions = emptyTournamentOptions();
  export let featureFlags: FeatureFlags = {};

  export let onSubmit = () => {
    console.log("Submitted: ", tournament);
  };
  export let submitLabel = "Save";
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
      <select
        id="time_zone"
        class="form-control"
        bind:value={tournament.time_zone}
      >
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
      <label for="registration_starts">Registration starts</label>
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
      <label for="tournament_starts">Tournament starts</label>
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

{#if featureFlags.single_sided_swiss}
  <div class="form-group">
    <label for="swiss_format">Swiss format</label>
    <select
      id="swiss_format"
      class="form-control"
      bind:value={tournament.swiss_format}
    >
      <option value="double_sided">Double-Sided</option>
      <option value="single_sided">Single-Sided</option>
    </select>
    {#if errors.swiss_format}
      <div class="invalid-feedback d-block">{errors.swiss_format}</div>
    {/if}
  </div>
{/if}

<div class="row">
  <div class="col-md-6">
    <div class="form-group">
      <label for="tournament_type_id">Tournament Type</label>
      <select
        id="tournament_type_id"
        class="form-control"
        bind:value={tournament.tournament_type_id}
      >
        <option value="">Select tournament type</option>
        {#each options.tournament_types as tournament_type (tournament_type.id)}
          <option value={tournament_type.id}>{tournament_type.name}</option>
        {/each}
      </select>
      {#if errors.tournament_type_id}
        <div class="invalid-feedback d-block">{errors.tournament_type_id}</div>
      {/if}
    </div>
  </div>
  <div class="col-md-6">
    <div class="form-group">
      <label for="card_set_id">Legal Cardpool Up To</label>
      <select
        id="card_set_id"
        class="form-control"
        bind:value={tournament.card_set_id}
      >
        <option value="">Select card set</option>
        {#each options.card_sets as card_set (card_set.id)}
          <option value={card_set.id}>{card_set.name}</option>
        {/each}
      </select>
      {#if errors.card_set_id}
        <div class="invalid-feedback d-block">{errors.card_set_id}</div>
      {/if}
    </div>
  </div>
</div>

<div class="row">
  <div class="col-md-6">
    <div class="form-group">
      <label for="format_id">Play Format</label>
      <select
        id="format_id"
        class="form-control"
        bind:value={tournament.format_id}
      >
        <option value="">Select format</option>
        {#each options.formats as format (format.id)}
          <option value={format.id}>{format.name}</option>
        {/each}
      </select>
      {#if errors.format_id}
        <div class="invalid-feedback d-block">{errors.format_id}</div>
      {/if}
    </div>
  </div>
  <div class="col-md-6">
    <div class="form-group">
      <label for="deckbuilding_restriction_id">Deckbuilding Restriction</label>
      <select
        id="deckbuilding_restriction_id"
        class="form-control"
        bind:value={tournament.deckbuilding_restriction_id}
      >
        <option value="">Select restriction</option>
        {#each options.deckbuilding_restrictions as restriction (restriction.id)}
          <option value={restriction.id}>{restriction.name}</option>
        {/each}
      </select>
      {#if errors.deckbuilding_restriction_id}
        <div class="invalid-feedback d-block">
          {errors.deckbuilding_restriction_id}
        </div>
      {/if}
    </div>
  </div>
</div>

<div class="form-check mb-3">
  <input
    type="checkbox"
    id="decklist_required"
    class="form-check-input"
    bind:checked={tournament.decklist_required}
  />
  <label for="decklist_required" class="form-check-label">
    Decklist required for event
  </label>
</div>

<div class="form-group">
  <label for="organizer_contact">Organizer Contact Information</label>
  <input
    type="text"
    id="organizer_contact"
    class="form-control"
    bind:value={tournament.organizer_contact}
  />
  {#if errors.organizer_contact}
    <div class="invalid-feedback d-block">{errors.organizer_contact}</div>
  {/if}
</div>

<div class="form-group">
  <label for="event_link">External Event Link</label>
  <input
    type="url"
    id="event_link"
    class="form-control"
    bind:value={tournament.event_link}
  />
  {#if errors.event_link}
    <div class="invalid-feedback d-block">{errors.event_link}</div>
  {/if}
</div>

<div class="form-group">
  <label for="description">Event Description (Markdown format supported)</label>
  <textarea
    id="description"
    class="form-control"
    rows="4"
    bind:value={tournament.description}
  ></textarea>
  {#if errors.description}
    <div class="invalid-feedback d-block">{errors.description}</div>
  {/if}
</div>

<div class="form-group">
  <label for="official_prize_kit_id">Official Prize Kit</label>
  <select
    id="official_prize_kit_id"
    class="form-control"
    bind:value={tournament.official_prize_kit_id}
  >
    <option value="">Select prize kit</option>
    {#each options.official_prize_kits as prize_kit (prize_kit.id)}
      <option value={prize_kit.id}>{prize_kit.name}</option>
    {/each}
  </select>
  {#if errors.official_prize_kit_id}
    <div class="invalid-feedback d-block">{errors.official_prize_kit_id}</div>
  {/if}
</div>

<div class="form-group">
  <label for="additional_prizes_description"
    >Additional Prize Information (Markdown format supported)</label
  >
  <textarea
    id="additional_prizes_description"
    class="form-control"
    rows="4"
    bind:value={tournament.additional_prizes_description}
  ></textarea>
  {#if errors.additional_prizes_description}
    <div class="invalid-feedback d-block">
      {errors.additional_prizes_description}
    </div>
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

{#if featureFlags.nrdb_deck_registration}
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
{/if}

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

<div class="form-check mb-3">
  <input
    type="checkbox"
    id="manual_seed"
    class="form-check-input"
    bind:checked={tournament.manual_seed}
  />
  <label for="manual_seed" class="form-check-label">
    Use manual seeding for tiebreakers: Players can be assigned a "seed" value
    that will be used before all other tiebreakers (in ascending order; i.e.
    Seed 1 wins all ties)
  </label>
</div>

{#if featureFlags.streaming_opt_out}
  <div class="form-check mb-3">
    <input
      type="checkbox"
      id="allow_streaming_opt_out"
      class="form-check-input"
      bind:checked={tournament.allow_streaming_opt_out}
    />
    <label for="allow_streaming_opt_out" class="form-check-label">
      Streaming opt out: Allow players to choose whether their games should be
      included in video coverage (defaults to yes, and players are notified that
      in a top cut it may not be possible to exclude them)
    </label>
  </div>
{/if}

{#if featureFlags.allow_self_reporting}
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
{/if}

<div class="form-group">
  <button
    type="submit"
    class="btn btn-primary"
    on:click|preventDefault={onSubmit}
    disabled={isSubmitting}
  >
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
