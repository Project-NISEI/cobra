import { describe, it, expect, vi, beforeEach } from "vitest";
import {
  loadNewTournament,
  createTournament,
  ValidationError,
  emptyTournamentOptions,
} from "./TournamentSettings";

// Mock global fetch
Object.defineProperty(global, "fetch", {
  value: vi.fn(),
});

// Fake global Routes object
Object.defineProperty(global, "Routes", {
  value: {
    new_tournament_path: () => "/tournaments/new",
    tournaments_path: () => "/tournaments",
  },
});

// Fake CSRF token
const csrfMeta = document.createElement("meta");
csrfMeta.name = "csrf-token";
csrfMeta.content = "mock-csrf-token";
document.head.appendChild(csrfMeta);

describe("TournamentSettings", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe("emptyTournamentOptions", () => {
    it("returns empty options object", () => {
      const options = emptyTournamentOptions();

      expect(options).toEqual({
        tournament_types: [],
        formats: [],
        card_sets: [],
        deckbuilding_restrictions: [],
        time_zones: [],
        official_prize_kits: [],
      });
    });
  });

  describe("loadNewTournament", () => {
    it("fetches tournament data successfully", async () => {
      const mockData = {
        tournament: { date: "2023-12-25", private: false },
        options: emptyTournamentOptions(),
        feature_flags: { single_sided_swiss: true },
      };

      vi.mocked(fetch).mockResolvedValue({
        json: () => Promise.resolve(mockData),
      } as Response);

      const result = await loadNewTournament();

      expect(fetch).toHaveBeenCalledWith("/tournaments/new", {
        headers: { Accept: "application/json" },
        method: "GET",
      });
      expect(result).toEqual(mockData);
    });
  });

  describe("createTournament", () => {
    it("creates tournament successfully", async () => {
      const mockResponse = {
        id: 123,
        name: "Test Tournament",
        url: "/tournaments/123",
      };

      vi.mocked(fetch).mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockResponse),
      } as Response);

      const tournament = {
        name: "Test Tournament",
        date: "2023-12-25",
        private: false,
      };

      const result = await createTournament(tournament);

      expect(fetch).toHaveBeenCalledWith("/tournaments", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": "mock-csrf-token",
        },
        body: JSON.stringify({ tournament }),
      });
      expect(result).toEqual(mockResponse);
    });

    it("throws ValidationError on 422 response", async () => {
      const mockErrors = {
        errors: {
          name: ["Name is required"],
          date: ["Date must be in the future"],
        },
      };

      vi.mocked(fetch).mockResolvedValue({
        ok: false,
        status: 422,
        json: () => Promise.resolve(mockErrors),
      } as Response);

      const tournament = { name: "", date: "" };

      await expect(createTournament(tournament)).rejects.toThrow(
        ValidationError,
      );

      try {
        await createTournament(tournament);
      } catch (error) {
        expect(error).toBeInstanceOf(ValidationError);
        expect((error as ValidationError).errors).toEqual(mockErrors.errors);
      }
    });

    it("throws generic error on other HTTP errors", async () => {
      vi.mocked(fetch).mockResolvedValue({
        ok: false,
        status: 500,
        statusText: "Internal Server Error",
      } as Response);

      const tournament = { name: "Test" };

      await expect(createTournament(tournament)).rejects.toThrow(
        "HTTP 500: Internal Server Error",
      );
    });
  });

  describe("ValidationError", () => {
    it("creates error with correct properties", () => {
      const errors = {
        name: ["Name is required"],
        date: ["Date is invalid"],
      };

      const error = new ValidationError(errors);

      expect(error.name).toBe("ValidationError");
      expect(error.message).toBe("Validation failed");
      expect(error.errors).toEqual(errors);
      expect(error).toBeInstanceOf(Error);
    });
  });
});
