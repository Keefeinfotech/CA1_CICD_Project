
/*
 * File Name: server.ts
 * Description: Starts the Personal Secretary API server.
 * Author: Keefe Chen
 * Date: 27 October 2026
 */

import "dotenv/config";
import app from "./app.js";
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
