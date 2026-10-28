
import express from "express";
import cors from "cors";
import { swaggerDocument, swaggerUi } from "./swagger.js";
import authRoutes from "./routes/auth.js";

const app = express();

app.use(cors());
app.use(express.json());
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));

app.get("/api/health", (_req, res) => {
  res.status(200).json({
    status: "ok",
    service: "personal-secretary-api"
  });
});

app.use("/api/auth", authRoutes);

export default app;
