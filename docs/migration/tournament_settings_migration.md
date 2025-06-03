# Tournament Settings/Edit Page Migration Plan

## Overview

This document outlines the plan to migrate the Tournament Settings/Edit page from Slim templates to Svelte components. This is part of the larger effort to gradually migrate the application from Rails Slim templates to a Svelte frontend.

## Current Implementation

The Tournament Settings page currently uses:
- `app/views/tournaments/edit.html.slim` - Main edit page
- `app/views/tournaments/_form.html.slim` - Form partial
- `TournamentsController#edit` and `#update` actions

## Migration Strategy

### 1. Update REST API Endpoints

The following endpoints already exist but need to be updated to handle JSON responses:

| Endpoint | HTTP Method | Status | Changes Needed |
|----------|------------|---------|---------------|
| `/tournaments/:id` | PATCH/PUT | Exists | Add JSON response format |
| `/tournaments/:id/upload_to_abr` | POST | Exists | Add JSON response format |
| `/tournaments/:id/cut` | POST | Exists | Add JSON response format |
| `/tournaments/:id/close_registration` | PATCH | Exists | Add JSON response format |
| `/tournaments/:id/open_registration` | PATCH | Exists | Add JSON response format |
| `/tournaments/:id/lock_player_registrations` | PATCH | Exists | Add JSON response format |
| `/tournaments/:id/unlock_player_registrations` | PATCH | Exists | Add JSON response format |

The following new endpoint needs to be created:

| Endpoint | HTTP Method | Status | Purpose |
|----------|------------|---------|---------|
| `/tournaments/:id/data` | GET | New | Fetch tournament data and related options |

**Important Note**: These endpoints must be updated to handle JSON responses before implementing the frontend components. Without proper JSON response handling:

- **Content Type Mismatch**: The server will respond with HTML content (the default format) even when the frontend expects JSON. When JavaScript tries to parse this HTML as JSON using `response.json()`, it will throw a parsing error.

- **Redirect Handling**: Many of the existing endpoints use redirects for HTML responses (e.g., `redirect_to edit_tournament_path(@tournament)`). When called via AJAX/fetch, the browser will follow these redirects, but JavaScript won't be notified about the redirect destination. The code will receive the HTML of the redirected page instead of actionable data.

- **Error Handling**: Without proper JSON responses for errors, the frontend won't receive structured error information. Instead, it might get a 500 error page in HTML format, making it difficult to display meaningful error messages to users.

- **Status Codes**: The existing endpoints might return 302 (redirect) status codes that the frontend isn't prepared to handle, rather than 200 (success) or 422 (validation error) that would be more appropriate for API responses.

- **CSRF Protection**: Rails' CSRF protection works differently for HTML vs. JSON requests. Without proper JSON handling, the application might encounter CSRF token verification failures.

### 2. Create Svelte Components

Create the following Svelte components:

- `TournamentSettings.svelte` - Main component
- `TournamentForm.svelte` - Form fields component
- `TournamentActions.svelte` - Tournament actions (cut, upload, etc.)

### 3. Integration Steps

1. Update existing endpoints to handle JSON responses
2. Create the new data endpoint
3. Build the Svelte components
4. Mount the components in the existing Slim template
5. Test thoroughly
6. Replace the Slim template entirely once stable

For implementation details, see [Tournament Settings Implementation Details](./tournament_settings_implementation.md).

## Testing Strategy

1. Unit test the API endpoints
2. Test the Svelte components with Jest and Testing Library
3. End-to-end testing with Cypress to ensure the form works correctly
4. Manual testing of the integration

## Rollout Plan

1. Deploy the API endpoint updates first
2. Add the Svelte components but keep them disabled
3. Enable for a subset of users/tournaments
4. Monitor for issues
5. Roll out to all users

## Fallback Strategy

If issues arise, we can easily revert to the Slim templates by removing the Svelte mount point and restoring the original template.