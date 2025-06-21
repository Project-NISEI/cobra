import { setupServer, SetupServerApi } from "msw/node";

/**
 * This creates a server for Mock Service Worker. Vitest is configured to manage
 * this so that it will be available for any test named in the format
 * MyName.msw-test.ts. This can be imported in those tests to fake server side
 * behaviour.
 */
export const server: SetupServerApi = setupServer();
