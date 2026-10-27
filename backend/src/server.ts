
/*
 * File Name: server.ts
 * Description: Starts the Personal Secretary API server.
 * Author: Keefe Chen
 * Date: 27 October 2026
 */

import "dotenv/config";
import app from "./app.js";
import process from "process";

const port = Number(process.env.PORT) || 3000;

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
