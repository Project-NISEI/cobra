import { render, screen, fireEvent } from "@testing-library/svelte";
import { describe, it, expect, vi } from "vitest";
import TournamentSettingsForm from "./TournamentSettingsForm.svelte";
import type {
  TournamentSettings,
  TournamentOptions,
  FeatureFlags,
} from "./TournamentSettings";

describe("TournamentSettingsForm", () => {
  const tournament: TournamentSettings = {
    name: "Test Tournament",
    date: "2023-12-25",
    private: false,
    swiss_format: "double_sided",
  };

  const options: TournamentOptions = {
    tournament_types: [
      { id: 1, name: "Store Championship" },
      { id: 2, name: "Regional Championship" },
    ],
    formats: [
      { id: 1, name: "Standard" },
      { id: 2, name: "Startup" },
    ],
    card_sets: [
      { id: 1, name: "System Gateway" },
      { id: 2, name: "System Update 2021" },
    ],
    deckbuilding_restrictions: [{ id: 1, name: "Standard Ban List" }],
    time_zones: [
      { id: "UTC", name: "(GMT+00:00) UTC" },
      {
        id: "America/New_York",
        name: "(GMT-05:00) Eastern Time (US & Canada)",
      },
    ],
    official_prize_kits: [{ id: 1, name: "2025 Q1 Game Night Kit" }],
  };

  const featureFlags: FeatureFlags = {
    allow_self_reporting: true
  };

  it("renders basic form fields", () => {
    render(TournamentSettingsForm, {
      props: {
        tournament: tournament,
        options: options,
        featureFlags: featureFlags,
      },
    });

    expect(screen.getByLabelText(/tournament name/i)).toBeInTheDocument();
    expect(screen.getByLabelText("Date")).toBeInTheDocument();
    expect(screen.getByLabelText(/private.*tournament/i)).toBeInTheDocument();
  });

  it("shows conditional fields when feature flags are enabled", () => {
    render(TournamentSettingsForm, {
      props: {
        tournament: tournament,
        options: options,
        featureFlags: featureFlags,
      },
    });

    expect(screen.getByLabelText("Swiss format")).toBeInTheDocument();
    expect(
      screen.getByLabelText("Deck registration: Upload decks from NetrunnerDB"),
    ).toBeInTheDocument();
    expect(
      screen.getByLabelText(
        "Allow logged-in players to report their own match results",
      ),
    ).toBeInTheDocument();
  });

  it("hides conditional fields when feature flags are disabled", () => {
    render(TournamentSettingsForm, {
      props: {
        tournament: tournament,
        options: options,
        featureFlags: {}, // All flags disabled
      },
    });

    expect(
      screen.queryByLabelText(
        "Allow logged-in players to report their own match results",
      ),
    ).not.toBeInTheDocument();
  });

  it("populates dropdown options correctly", () => {
    render(TournamentSettingsForm, {
      props: {
        tournament: tournament,
        options: options,
        featureFlags: featureFlags,
      },
    });

    const tournamentTypeSelect = screen.getByLabelText("Tournament Type");
    expect(tournamentTypeSelect).toBeInTheDocument();

    // Check that options are present
    expect(screen.getByText("Store Championship")).toBeInTheDocument();
    expect(screen.getByText("Regional Championship")).toBeInTheDocument();
  });

  it("calls onSubmit when form is submitted", async () => {
    const mockOnSubmit = vi.fn();

    render(TournamentSettingsForm, {
      props: {
        tournament: tournament,
        options: options,
        featureFlags: featureFlags,
        onSubmit: mockOnSubmit,
      },
    });

    const submitButton = screen.getByRole("button", { name: /save/i });
    await fireEvent.click(submitButton);

    expect(mockOnSubmit).toHaveBeenCalledOnce();
  });

  it("displays validation errors", () => {
    const errors = {
      name: ["Name is required"],
      date: ["Date must be in the future"],
    };

    render(TournamentSettingsForm, {
      props: {
        tournament: tournament,
        options: options,
        featureFlags: featureFlags,
        errors,
      },
    });

    expect(screen.getByText("Name is required")).toBeInTheDocument();
    expect(screen.getByText("Date must be in the future")).toBeInTheDocument();
  });

  it("shows loading state when submitting", () => {
    render(TournamentSettingsForm, {
      props: {
        tournament: tournament,
        options: options,
        featureFlags: featureFlags,
        isSubmitting: true,
        submitLabel: "Saving...",
      },
    });

    const submitButton = screen.getByRole("button", { name: /saving/i });
    expect(submitButton).toBeDisabled();
  });
});
