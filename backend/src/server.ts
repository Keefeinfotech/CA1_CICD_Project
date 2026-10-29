
/*
 * File Name: server.ts
 * Description: Starts the API after connecting to MongoDB.
 * Author: Keefe Chen
 * Date: 27 October 2026
 */

import "dotenv/config";
import app from "./app.js";
<<<<<<< HEAD
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
=======
import process from "process";
import connectDB from "../config/database.js";

const port = Number(process.env.PORT) || 3000;

const start = async () => {
  try {
    if (process.env.NODE_ENV !== "test") {
      await connectDB();
    }
  } catch (err) {
    console.error(err);
  }
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });
};

start();
>>>>>>> fb6bdc89e53b88575b70315361baf5131f501801
