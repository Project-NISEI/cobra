import { describe, it, expect } from "vitest";
import { http, HttpResponse } from "msw";
import {
  loadNewDemoTournament,
  createDemoTournament,
  ValidationError,
} from "./DemoTournamentSettings";
import { server } from "../msw/server";
import {
  create_demo_tournaments_path,
  new_demo_form_tournaments_path,
} from "../msw/routes";

describe("DemoTournamentSettings", () => {
  describe("loadNewDemoTournament", () => {
    it("fetches new tournament form data", async () => {
      const mockData = {
        tournament: {
          name: null,
          swiss_format: "single_sided",
          num_players: null,
          num_first_round_byes: null,
          assign_ids: false,
        },
      };

      server.use(
        http.get(new_demo_form_tournaments_path(), ({ request }) => {
          expect(request.headers.get("Accept")).toBe("application/json");
          return HttpResponse.json(mockData);
        }),
      );

      const result = await loadNewDemoTournament();
      expect(result).toEqual(mockData);
    });

    it("handles network errors", async () => {
      server.use(
        http.get(new_demo_form_tournaments_path(), () => {
          return HttpResponse.error();
        }),
      );

      await expect(loadNewDemoTournament()).rejects.toThrow();
    });
  });

  describe("createDemoTournament", () => {
    it("creates a demo tournament", async () => {
      const mockResponse = {
        id: 123,
        name: "Test Demo Tournament",
        url: "/tournaments/123/rounds",
      };

      const tournament = {
        name: "Test Tournament",
        swiss_format: "single_sided",
        num_players: 8,
        num_first_round_byes: 0,
        assign_ids: false,
      };

      server.use(
        http.post(create_demo_tournaments_path(), async ({ request }) => {
          expect(request.headers.get("Content-Type")).toBe("application/json");
          expect(request.headers.get("Accept")).toBe("application/json");
          expect(request.headers.get("X-CSRF-Token")).toBe("mock-csrf-token");

          const body = await request.json();
          expect(body).toEqual({ tournament });

          return HttpResponse.json(mockResponse);
        }),
      );

      const result = await createDemoTournament("mock-csrf-token", tournament);
      expect(result).toEqual(mockResponse);
    });

    it("handles validation errors", async () => {
      const mockErrors = {
        errors: {
          name: ["Name is required"],
          first_round_byes: ["Number of byes must be a number"],
        },
      };

      server.use(
        http.post(create_demo_tournaments_path(), () => {
          return HttpResponse.json(mockErrors, { status: 422 });
        }),
      );

      const tournament = { name: "" };

      await expect(
        createDemoTournament("mock-csrf-token", tournament),
      ).rejects.toThrow(ValidationError);
    });

    it("handles server errors", async () => {
      server.use(
        http.post(create_demo_tournaments_path(), () => {
          return HttpResponse.json(
            { error: "Internal Server Error" },
            { status: 500, statusText: "Internal Server Error" },
          );
        }),
      );

      const tournament = { name: "Test" };

      await expect(
        createDemoTournament("mock-csrf-token", tournament),
      ).rejects.toThrow("HTTP 500: Internal Server Error");
    });
  });
});
