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

For implementation details, see [Tournament Settings Implementation Details](tournament_settings_implementation.md).

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