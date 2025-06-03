# Tournament Settings/Edit Page Migration Plan

## Overview

This document outlines the plan to migrate the Tournament Settings/Edit page from Slim templates to Svelte components. This is part of the larger effort to gradually migrate the application from Rails Slim templates to a Svelte frontend.

## Current Implementation

The Tournament Settings page currently uses:
- `app/views/tournaments/edit.html.slim` - Main edit page
- `app/views/tournaments/_form.html.slim` - Form partial
- `TournamentsController#edit` and `#update` actions

## Migration Strategy

### 1. Create REST API Endpoints

First, add JSON endpoints to the `TournamentsController`:

| Endpoint | HTTP Method | Purpose |
|----------|------------|---------|
| `/tournaments/:id/data` | GET | Fetch tournament data and related options |
| `/tournaments/:id` | PATCH/PUT | Update tournament settings |
| `/tournaments/:id/upload_to_abr` | POST | Upload to ABR |
| `/tournaments/:id/cut` | POST | Cut to elimination rounds |
| `/tournaments/:id/close_registration` | PATCH | Close registration |
| `/tournaments/:id/open_registration` | PATCH | Open registration |
| `/tournaments/:id/lock_player_registrations` | PATCH | Lock player registrations |
| `/tournaments/:id/unlock_player_registrations` | PATCH | Unlock player registrations |

### 2. Create Svelte Components

Create the following Svelte components:

- `TournamentSettings.svelte` - Main component
- `TournamentForm.svelte` - Form fields component
- `TournamentActions.svelte` - Tournament actions (cut, upload, etc.)

### 3. Integration Steps

1. Create the API endpoints first
2. Build the Svelte components
3. Mount the components in the existing Slim template
4. Test thoroughly
5. Replace the Slim template entirely once stable

## Implementation Details

### API Endpoint Implementation

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

### Routes Update

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

### Svelte Component Structure

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

### Integration with Existing Template

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

## Testing Strategy

1. Unit test the API endpoints
2. Test the Svelte components with Jest and Testing Library
3. End-to-end testing with Cypress to ensure the form works correctly
4. Manual testing of the integration

## Rollout Plan

1. Deploy the API endpoints first
2. Add the Svelte components but keep them disabled
3. Enable for a subset of users/tournaments
4. Monitor for issues
5. Roll out to all users

## Fallback Strategy

If issues arise, we can easily revert to the Slim templates by removing the Svelte mount point and restoring the original template.