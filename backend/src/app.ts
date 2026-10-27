
import express from "express";
import { swaggerDocument, swaggerUi } from "./swagger.js";

const app = express();

app.use(express.json());
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));

app.get("/api/health", (_req, res) => {
  res.status(200).json({
    status: "ok",
    service: "personal-secretary-api"
  });
});

export default app;
