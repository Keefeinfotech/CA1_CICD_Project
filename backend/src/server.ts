
/*
 * File Name: server.ts
 * Description: Starts the API after connecting to MongoDB.
 * Author: Keefe Chen
 * Date: 27 October 2026
 */

import "dotenv/config";
import app from "./app.js";
import { connectDatabase } from "./database.js";

const port = Number(process.env.PORT) || 3000;

async function startServer(): Promise<void> {
  try {
    await connectDatabase();

    app.listen(port, () => {
      console.log(`Server running on port ${port}`);
    });
  } catch (error) {
    console.error("Failed to start server:", error);
    process.exit(1);
  }
}

startServer();
