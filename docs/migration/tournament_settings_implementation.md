# Tournament Settings Implementation Details

This document contains the technical implementation details for migrating the Tournament Settings/Edit page to Svelte.

## API Endpoint Implementation

```ruby
# In tournaments_controller.rb

# New endpoint to fetch tournament data
def data
  authorize @tournament, :edit?
  
  render json: {
    tournament: @tournament.as_json(include: [:tournament_type, :format, :card_set, :deckbuilding_restriction]),
    tournament_types: TournamentType.all,
    formats: Format.all,
    card_sets: CardSet.all,
    deckbuilding_restrictions: DeckbuildingRestriction.all,
    official_prize_kits: OfficialPrizeKit.all
  }
end

# Update existing update method to handle JSON
def update
  authorize @tournament

  if @tournament.update(tournament_params)
    respond_to do |format|
      format.html { redirect_to edit_tournament_path(@tournament), notice: 'Tournament updated successfully.' }
      format.json { render json: { success: true, tournament: @tournament } }
    end
  else
    respond_to do |format|
      format.html { render :edit }
      format.json { render json: { success: false, errors: @tournament.errors }, status: :unprocessable_entity }
    end
  end
end

# Update action endpoints to handle JSON responses
def upload_to_abr
  authorize @tournament

  response = AbrUpload.new(@tournament).upload!
  @tournament.update(abr_code: response[:code]) if response[:code]

  respond_to do |format|
    format.html { redirect_to edit_tournament_path(@tournament) }
    format.json { render json: { success: true, abr_code: @tournament.abr_code } }
  end
end

# Similar updates for other action endpoints
```

## Routes Update

```ruby
# In config/routes.rb
resources :tournaments do
  member do
    get :data
    # Existing routes remain unchanged
    post :upload_to_abr
    post :cut
    patch :close_registration
    patch :open_registration
    # etc.
  end
end
```

## Svelte Component Structure

### Main Component

```typescript
// app/frontend/tournament/TournamentSettings.svelte
<script lang="ts">
  import { onMount } from 'svelte';
  import TournamentForm from './TournamentForm.svelte';
  import TournamentActions from './TournamentActions.svelte';
  
  export let tournamentId: string;
  
  let tournament: any = null;
  let options: any = {};
  let loading = true;
  let error = null;
  
  onMount(async () => {
    try {
      const response = await fetch(`/tournaments/${tournamentId}/data`);
      const data = await response.json();
      tournament = data.tournament;
      options = {
        tournamentTypes: data.tournament_types,
        formats: data.formats,
        cardSets: data.card_sets,
        deckbuildingRestrictions: data.deckbuilding_restrictions,
        officialPrizeKits: data.official_prize_kits
      };
      loading = false;
    } catch (e) {
      error = e;
      loading = false;
    }
  });
  
  async function handleSave(formData) {
    // Implementation for saving tournament data
  }
</script>

{#if loading}
  <div class="loading">Loading...</div>
{:else if error}
  <div class="error">Error loading tournament data</div>
{:else}
  <div class="row">
    <div class="col-md-6">
      <TournamentForm 
        {tournament} 
        {options} 
        on:save={handleSave} 
      />
    </div>
    <div class="col-md-6">
      <TournamentActions 
        {tournament} 
        {tournamentId} 
      />
    </div>
  </div>
{/if}
```

### Form Component

```typescript
// app/frontend/tournament/TournamentForm.svelte
<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  
  export let tournament;
  export let options;
  
  const dispatch = createEventDispatcher();
  
  function handleSubmit() {
    dispatch('save', tournament);
  }
</script>

<form on:submit|preventDefault={handleSubmit}>
  <!-- Form fields for tournament settings -->
  <div class="form-group">
    <label for="name">Tournament Name</label>
    <input type="text" class="form-control" id="name" bind:value={tournament.name}>
  </div>
  
  <!-- More form fields... -->
  
  <button type="submit" class="btn btn-primary">Save Changes</button>
</form>
```

### Actions Component

```typescript
// app/frontend/tournament/TournamentActions.svelte
<script lang="ts">
  export let tournament;
  export let tournamentId;
  
  async function uploadToAbr() {
    // Implementation for ABR upload
  }
  
  async function cutToElimination() {
    // Implementation for cutting to elimination rounds
  }
  
  async function toggleRegistration() {
    // Implementation for opening/closing registration
  }
</script>

<div class="card">
  <div class="card-header">Tournament Actions</div>
  <div class="card-body">
    <button class="btn btn-primary mb-2" on:click={uploadToAbr}>
      Upload to ABR
    </button>
    
    <button class="btn btn-warning mb-2" on:click={cutToElimination}>
      Cut to Elimination Rounds
    </button>
    
    <button class="btn btn-secondary mb-2" on:click={toggleRegistration}>
      {tournament.registration_open ? 'Close' : 'Open'} Registration
    </button>
    
    <!-- More action buttons... -->
  </div>
</div>
```

## Integration with Existing Template

```slim
// Modified app/views/tournaments/edit.html.slim
.row
  #tournament-settings-container data-tournament-id=@tournament.id
  
// JavaScript to mount the component
// app/frontend/entrypoints/tournament_settings.ts
import { mount } from 'svelte';
import TournamentSettings from '../tournament/TournamentSettings.svelte';

document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('tournament-settings-container');
  if (container) {
    mount(TournamentSettings, {
      target: container,
      props: {
        tournamentId: container.dataset.tournamentId
      }
    });
  }
});
```

## Data Types

```typescript
// app/frontend/tournament/types.ts
export interface Tournament {
  id: number;
  name: string;
  description: string;
  registration_open: boolean;
  player_registrations_locked: boolean;
  // Other tournament properties...
  tournament_type: TournamentType;
  format: Format;
  card_set: CardSet;
  deckbuilding_restriction: DeckbuildingRestriction;
}

export interface TournamentType {
  id: number;
  name: string;
}

export interface Format {
  id: number;
  name: string;
}

// Other interfaces...
```