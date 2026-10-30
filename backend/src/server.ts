
/*
 * File Name: server.ts
 * Description: Validates runtime configuration and starts the Auxilia API.
 * Author: Keefe Chen
 * Date: 27 October 2026
 */

import "dotenv/config";
import process from "node:process";
import mongoose from "mongoose";
import app from "./app.js";
import connectDB from "../config/database.js";
import { assertRuntimeEnv, EnvError } from "./config/env.js";

const port = Number(process.env.PORT) || 3000;

const start = async (): Promise<void> => {
  // Validate environment variables before starting the application.
  try {
    assertRuntimeEnv();
  } catch (err) {
    const message =
      err instanceof EnvError
        ? err.message
        : "Invalid configuration";

    console.error(`[startup] ${message}`);
    process.exit(1);
  }

  // Establish the database connection.
  try {
    await connectDB();
  } catch (err) {
    const message =
      err instanceof Error
        ? err.message
        : "Unknown database error";

    console.error(
      `[startup] Database connection failed: ${message}`
    );

    process.exit(1);
  }

  // Start the Express server after successful database connection.
  const server = app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });

  // Gracefully shut down the server and database connection.
  const shutdown = (signal: string): void => {
    console.log(`[shutdown] Received ${signal}`);

    server.close(() => {
      void mongoose.connection
        .close()
        .finally(() => process.exit(0));
    });
  };

  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));
};

void start();
