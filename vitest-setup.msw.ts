// Create MSW server
import { afterAll, afterEach, beforeAll } from "vitest";
import { server } from "./app/frontend/msw/server";

beforeAll(() => {
  server.listen();
});

afterEach(() => {
  server.resetHandlers();
});

afterAll(() => {
  server.close();
});
