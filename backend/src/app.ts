import express from "express";
import cors from "cors";
import { swaggerDocument, swaggerUi } from "./config/swagger.js";
import { isProduction, shouldTrustProxy } from "./config/environment.js";
import {
  corsOptions,
  helmetMiddleware,
  jsonBodyOptions,
  urlEncodedBodyOptions,
} from "./config/security.js";
import { errorHandler } from "./middleware/errorHandler.js";
import { notFound } from "./middleware/notFound.js";
import { requestId } from "./middleware/requestId.js";
import authRoutes from "./modules/auth/auth.routes.js";
import aiRoutes from "./modules/ai/ai.routes.js";
import healthRoutes from "./modules/health/health.routes.js";

const app = express();

app.disable("x-powered-by");
app.set("json escape", true);

if (shouldTrustProxy()) {
  app.set("trust proxy", 1);
}

app.use(requestId);
app.use(helmetMiddleware);
app.use(cors(corsOptions));
app.use(express.json(jsonBodyOptions));
app.use(express.urlencoded(urlEncodedBodyOptions));

if (!isProduction()) {
  app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));
}

app.use("/api/health", healthRoutes);
app.use(
  "/api/auth",
  (_req, res, next) => {
    res.setHeader("Cache-Control", "no-store");
    next();
  },
  authRoutes
);
app.use("/api/ai", aiRoutes);

app.use(notFound);
app.use(errorHandler);

export default app;
