/**
 * This sets up fake routes for the purposes of tests with Mock Service Worker.
 * Normally routes are set in the global "Routes" object by the Ruby gem
 * js-routes. We reproduce that for Mock Service Worker here. The methods below
 * can be used to retrieve the URLs used in Mock Service Worker tests.
 */

const basePath = "https://localhost:3000";

export function new_form_tournaments_path() {
  return `${basePath}/tournaments/new`;
}

export function edit_form_tournament_path(id: number) {
  return `${basePath}/tournaments/${id.toString()}/edit_form`;
}

export function tournaments_path() {
  return `${basePath}/tournaments`;
}

Object.defineProperty(global, "Routes", {
  value: {
    new_form_tournaments_path,
    edit_form_tournament_path,
    tournaments_path,
  },
});
