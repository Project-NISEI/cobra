const basePath = "https://localhost:3000";

export function new_tournament_path() {
  return `${basePath}/tournaments/new`;
}

export function tournaments_path() {
  return `${basePath}/tournaments`;
}

Object.defineProperty(global, "Routes", {
  value: {
    new_tournament_path,
    tournaments_path,
  },
});
