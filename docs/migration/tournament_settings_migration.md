# Tournament Settings Page Migration Plan

## Overview

This document outlines the plan to migrate the Tournament Settings page from
Slim templates to Svelte components.

These pages share much of the same form structure and functionality, making them
ideal to migrate together. This is part of the larger effort to gradually
migrate the application from Rails Slim templates to a Svelte frontend.

## Current Implementation

The Tournament Settings and Creation pages currently use:
- `app/views/tournaments/edit.html.slim` - Edit page
- `app/views/tournaments/new.html.slim` - Creation page
- `app/views/tournaments/_form.html.slim` - Shared form partial
- Several controller actions in `TournamentsController`:
  - `#new` - Displays the creation form
  - `#create` - Creates a new tournament
  - `#edit` - Displays the edit form
  - `#update` - Updates tournament settings
  - `#upload_to_abr` - Uploads tournament to ABR
  - `#cut` - Cuts to elimination rounds
  - `#close_registration` - Closes registration
  - `#open_registration` - Opens registration
  - `#lock_player_registrations` - Locks player registrations
  - `#unlock_player_registrations` - Unlocks player registrations

## Migration Strategy

### 1. Update REST API Endpoints

The following endpoints already exist but need to be updated to handle JSON responses:

| Endpoint                                       | HTTP Method | Changes Needed                                                         |
|------------------------------------------------|-------------|------------------------------------------------------------------------|
| `/tournaments/new`                             | GET         | Add JSON response format to return form options data                   |
| `/tournaments`                                 | POST        | Add JSON response format                                               |
| `/tournaments/:id/edit`                        | GET         | Add JSON response format to return tournament data and related options |
| `/tournaments/:id`                             | PATCH/PUT   | Add JSON response format                                               |
| `/tournaments/:id/upload_to_abr`               | POST        | Add JSON response format                                               |
| `/tournaments/:id/cut`                         | POST        | Add JSON response format                                               |
| `/tournaments/:id/close_registration`          | PATCH       | Add JSON response format                                               |
| `/tournaments/:id/open_registration`           | PATCH       | Add JSON response format                                               |
| `/tournaments/:id/lock_player_registrations`   | PATCH       | Add JSON response format                                               |
| `/tournaments/:id/unlock_player_registrations` | PATCH       | Add JSON response format                                               |

**Important Note**: These endpoints must be updated to handle JSON responses before implementing the frontend components. Without proper JSON response handling:

- **Content Type Mismatch**: The server will respond with HTML content (the default format) even when the frontend expects JSON. When JavaScript tries to parse this HTML as JSON using `response.json()`, it will throw a parsing error.

- **Redirect Handling**: Many of the existing endpoints use redirects for HTML responses (e.g., `redirect_to edit_tournament_path(@tournament)`). When called via AJAX/fetch, the browser will follow these redirects, but JavaScript won't be notified about the redirect destination. The code will receive the HTML of the redirected page instead of actionable data.

- **Error Handling**: Without proper JSON responses for errors, the frontend won't receive structured error information. Instead, it might get a 500 error page in HTML format, making it difficult to display meaningful error messages to users.

- **Status Codes**: The existing endpoints might return 302 (redirect) status codes that the frontend isn't prepared to handle, rather than 200 (success) or 422 (validation error) that would be more appropriate for API responses.

- **CSRF Protection**: Rails' CSRF protection works differently for HTML vs. JSON requests. Without proper JSON handling, the application might encounter CSRF token verification failures.

### 2. Create Svelte Components

Create the following Svelte components:

- `TournamentForm.svelte` - Shared form fields component used by both creation and editing
- `TournamentCreation.svelte` - Tournament creation component
- `TournamentSettings.svelte` - Tournament settings/edit component
- `TournamentActions.svelte` - Tournament actions (cut, upload, etc.) for the settings page

### 3. Integration Steps

1. Update existing endpoints to handle JSON responses
2. Build the Svelte components
3. Mount the components in the existing Slim templates
4. Test thoroughly
5. Replace the Slim templates entirely once stable

For implementation details, see [Tournament Settings Implementation Details](./tournament_settings_implementation.md).

## Testing Strategy

1. Unit test the API endpoints
2. Test the Svelte components with Jest and Testing Library
3. End-to-end testing with Cypress to ensure the forms work correctly
4. Manual testing of the integration

## Fallback Strategy

If issues arise, we can easily revert to the Slim templates by removing the Svelte mount points and restoring the original templates.
