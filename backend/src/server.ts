import "dotenv/config";
import process from "node:process";
import app from "./app.js";
import { connectDatabase, disconnectDatabase } from "./config/database.js";
import {
  assertRuntimeEnv,
  EnvError,
  getPort,
} from "./config/environment.js";

const start = async (): Promise<void> => {
  try {
    assertRuntimeEnv();
  } catch (err) {
    const message =
      err instanceof EnvError ? err.message : "Invalid configuration";
    console.error(`[startup] ${message}`);
    process.exit(1);
  }

  // Establish the database connection.
  try {
    await connectDatabase();
  } catch (err) {
    const message =
      err instanceof Error ? err.message : "Unknown database error";
    console.error(`[startup] Database connection failed: ${message}`);
    process.exit(1);
  }

  const port = getPort();
  const server = app.listen(port, () => {
    console.log(`[startup] Server running on port ${port}`);
  });

  let shuttingDown = false;

  const shutdown = (signal: string): void => {
    if (shuttingDown) return;
    shuttingDown = true;
    console.log(`[shutdown] Received ${signal}`);

    const forceExit = setTimeout(() => {
      console.error("[shutdown] Forced exit after timeout");
      process.exit(1);
    }, 10_000);
    forceExit.unref();

    server.close(() => {
      void disconnectDatabase().finally(() => {
        clearTimeout(forceExit);
        process.exit(0);
      });
    });
  };

  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));
};

void start();
