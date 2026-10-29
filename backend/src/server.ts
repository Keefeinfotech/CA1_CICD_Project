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

const start = async () => {
  try {
    assertRuntimeEnv();
  } catch (err) {
    const message = err instanceof EnvError ? err.message : "Invalid configuration";
    console.error(`[startup] ${message}`);
    process.exit(1);
  }

  try {
    await connectDB();
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown database error";
    console.error(`[startup] Database connection failed: ${message}`);
    process.exit(1);
  }

  const server = app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });

  const shutdown = async (signal: string) => {
    console.log(`[shutdown] Received ${signal}`);
    server.close(() => {
      void mongoose.connection.close().finally(() => process.exit(0));
    });
  };

  process.on("SIGTERM", () => void shutdown("SIGTERM"));
  process.on("SIGINT", () => void shutdown("SIGINT"));
};

void start();
