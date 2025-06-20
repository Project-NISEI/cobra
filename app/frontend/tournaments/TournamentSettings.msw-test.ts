import { describe, it, expect } from "vitest";
import { http, HttpResponse } from "msw";
import {
  loadNewTournament,
  createTournament,
  ValidationError,
  emptyTournamentOptions,
} from "./TournamentSettings";
import { server } from "../msw/server";
import { new_tournament_path, tournaments_path } from "../msw/routes";

describe("TournamentSettings", () => {
  describe("loadNewTournament", () => {
    it("fetches new tournament form data", async () => {
      const mockData = {
        tournament: { date: "2023-12-25", private: false },
        options: emptyTournamentOptions(),
        feature_flags: { single_sided_swiss: true },
      };

      server.use(
        http.get(new_tournament_path(), ({ request }) => {
          expect(request.headers.get("Accept")).toBe("application/json");
          return HttpResponse.json(mockData);
        }),
      );

      const result = await loadNewTournament();
      expect(result).toEqual(mockData);
    });

    it("handles network errors", async () => {
      server.use(
        http.get(new_tournament_path(), () => {
          return HttpResponse.error();
        }),
      );

      await expect(loadNewTournament()).rejects.toThrow();
    });
  });

  describe("createTournament", () => {
    it("creates a tournament", async () => {
      const mockResponse = {
        id: 123,
        name: "Test Tournament",
        url: "/tournaments/123",
      };

      const tournament = {
        name: "Test Tournament",
        date: "2023-12-25",
        private: false,
      };

      server.use(
        http.post(tournaments_path(), async ({ request }) => {
          expect(request.headers.get("Content-Type")).toBe("application/json");
          expect(request.headers.get("Accept")).toBe("application/json");
          expect(request.headers.get("X-CSRF-Token")).toBe("mock-csrf-token");

          const body = await request.json();
          expect(body).toEqual({ tournament });

          return HttpResponse.json(mockResponse);
        }),
      );

      const result = await createTournament("mock-csrf-token", tournament);
      expect(result).toEqual(mockResponse);
    });

    it("handles validation errors", async () => {
      const mockErrors = {
        errors: {
          name: ["Name is required"],
          date: ["Date must be in the future"],
        },
      };

      server.use(
        http.post(tournaments_path(), () => {
          return HttpResponse.json(mockErrors, { status: 422 });
        }),
      );

      const tournament = { name: "", date: "" };

      await expect(
        createTournament("mock-csrf-token", tournament),
      ).rejects.toThrow(ValidationError);
    });

    it("handles server errors", async () => {
      server.use(
        http.post(tournaments_path(), () => {
          return HttpResponse.json(
            { error: "Internal Server Error" },
            { status: 500, statusText: "Internal Server Error" },
          );
        }),
      );

      const tournament = { name: "Test" };

      await expect(
        createTournament("mock-csrf-token", tournament),
      ).rejects.toThrow("HTTP 500: Internal Server Error");
    });
  });
});
