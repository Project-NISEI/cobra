import { render, screen, fireEvent, waitFor } from "@testing-library/svelte";
import { describe, it, expect, vi, beforeEach } from "vitest";
import DemoTournamentCreation from "./DemoTournamentCreation.svelte";
import { ValidationError } from "./DemoTournamentSettings";

// Mock the DemoTournamentSettings module
vi.mock("./DemoTournamentSettings", async (importOriginal) => ({
  ...(await importOriginal<typeof import("./DemoTournamentSettings")>()),
  loadNewDemoTournament: vi.fn(),
  createDemoTournament: vi.fn(),
}));

describe("DemoTournamentCreation", () => {
  const mockTournamentData = {
    tournament: {
      name: "Test Demo Tournament",
      swiss_format: "single_sided",
      num_players: 16,
      num_first_round_byes: 1,
      assign_ids: true,
    },
    csrf_token: "fake-csrf-token",
  };

  beforeEach(async () => {
    vi.clearAllMocks();

    // Mock loadNewTournament to return test data
    const { loadNewDemoTournament } = await import("./DemoTournamentSettings");
    vi.mocked(loadNewDemoTournament).mockResolvedValue(mockTournamentData);
  });

  it("renders the demo tournament creation form", async () => {
    render(DemoTournamentCreation);

    await waitFor(() => {
      expect(screen.getByText("Create a demo tournament")).toBeInTheDocument();
    });

    expect(screen.getByLabelText(/tournament name/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Number of Players/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/swiss format/i)).toBeInTheDocument();
    expect(
      screen.getByLabelText(/number of first round byes/i),
    ).toBeInTheDocument();
    expect(
      screen.getByLabelText(/assign random ids for players\?/i),
    ).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /create/i })).toBeInTheDocument();
  });

  it("loads initial tournament data on mount", async () => {
    const { loadNewDemoTournament } = await import("./DemoTournamentSettings");

    render(DemoTournamentCreation);

    await waitFor(() => {
      expect(loadNewDemoTournament).toHaveBeenCalledOnce();
    });
  });

  it("shows a loading spinner", async () => {
    const { loadNewDemoTournament } = await import("./DemoTournamentSettings");
    vi.mocked(loadNewDemoTournament).mockImplementation(
      () =>
        new Promise(() => {
          // This promise intentionally never resolves to test loading state
        }),
    );

    render(DemoTournamentCreation);

    await waitFor(() => {
      expect(screen.getByText("Create a demo tournament")).toBeInTheDocument();
    });
    expect(screen.queryByLabelText(/tournament name/i)).not.toBeInTheDocument();
    expect(screen.getByTestId("loading-spinner")).toBeInTheDocument();
  });

  it("successfully creates a tournament", async () => {
    const mockResponse = {
      id: 123,
      name: "Test Demo Tournament",
      url: "/tournaments/123/rounds",
    };

    const { createDemoTournament } = await import("./DemoTournamentSettings");
    vi.mocked(createDemoTournament).mockResolvedValue(mockResponse);

    // Mock window.location.href
    const mockLocation = { href: "" };
    Object.defineProperty(window, "location", {
      value: mockLocation,
      writable: true,
    });

    render(DemoTournamentCreation);

    await waitFor(() => {
      expect(screen.getByLabelText(/tournament name/i)).toBeInTheDocument();
    });

    // Fill in the form
    const nameInput = screen.getByLabelText(/tournament name/i);
    await fireEvent.input(nameInput, {
      target: { value: "Test Demo Tournament" },
    });
    const formatInput = screen.getByLabelText(/swiss format/i);
    await fireEvent.change(formatInput, { target: { value: "Single-sided" } });
    const numPlayersInput = screen.getByLabelText(/number of players/i);
    await fireEvent.input(numPlayersInput, { target: { value: "16" } });
    const numByesInput = screen.getByLabelText(/number of first round byes/i);
    await fireEvent.input(numByesInput, { target: { value: "1" } });
    const assignIdsCheckbox = screen.getByLabelText(
      /assign random ids for players\?/i,
    );
    await fireEvent.click(assignIdsCheckbox);

    // Submit the form
    const submitButton = screen.getByRole("button", {
      name: /create/i,
    });
    await fireEvent.click(submitButton);

    await waitFor(() => {
      expect(createDemoTournament).toHaveBeenCalledWith(
        "fake-csrf-token",
        expect.objectContaining({
          name: "Test Demo Tournament",
        }),
      );
    });

    // Check that redirect happens
    await waitFor(() => {
      expect(mockLocation.href).toBe("/tournaments/123/rounds");
    });
  });

  it("handles validation errors", async () => {
    const { createDemoTournament } = await import("./DemoTournamentSettings");
    const validationError = new ValidationError({
      name: ["You must provide a name for the tournament"],
      num_players: ["Number of players is required"],
      num_first_round_byes: ["Number of byes must be a number"],
    });
    vi.mocked(createDemoTournament).mockRejectedValue(validationError);

    render(DemoTournamentCreation);

    await waitFor(() => {
      expect(screen.getByLabelText(/tournament name/i)).toBeInTheDocument();
    });

    const numByesInput = screen.getByLabelText(/number of first round byes/i);
    await fireEvent.input(numByesInput, {
      target: { value: "plural is not a number" },
    });

    // Submit the form
    const submitButton = screen.getByRole("button", {
      name: /create/i,
    });
    await fireEvent.click(submitButton);

    await waitFor(() => {
      expect(
        screen.getByText("You must provide a name for the tournament"),
      ).toBeInTheDocument();
      expect(
        screen.getByText("Number of players is required"),
      ).toBeInTheDocument();
      expect(
        screen.getByText("Number of byes must be a number"),
      ).toBeInTheDocument();
    });
  });

  it("handles unexpected errors", async () => {
    const { createDemoTournament } = await import("./DemoTournamentSettings");
    vi.mocked(createDemoTournament).mockRejectedValue(
      new Error("Network error"),
    );

    render(DemoTournamentCreation);

    await waitFor(() => {
      expect(screen.getByLabelText(/tournament name/i)).toBeInTheDocument();
    });

    // Submit the form
    const submitButton = screen.getByRole("button", {
      name: /create/i,
    });
    await fireEvent.click(submitButton);

    await waitFor(() => {
      expect(
        screen.getByText(/an unexpected error occurred/i),
      ).toBeInTheDocument();
    });
  });

  it("disables submit button while submitting", async () => {
    const { createDemoTournament } = await import("./DemoTournamentSettings");
    // Make createDemoTournament hang to test loading state
    vi.mocked(createDemoTournament).mockImplementation(
      () =>
        new Promise(() => {
          // This promise intentionally never resolves to test loading state
        }),
    );

    render(DemoTournamentCreation);

    await waitFor(() => {
      expect(screen.getByLabelText(/tournament name/i)).toBeInTheDocument();
    });

    const submitButton = screen.getByRole("button", {
      name: /create/i,
    });
    await fireEvent.click(submitButton);

    // Button should be disabled while submitting
    await waitFor(() => {
      expect(submitButton).toBeDisabled();
    });
  });
});
