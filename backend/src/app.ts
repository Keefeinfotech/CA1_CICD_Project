
import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import { swaggerDocument, swaggerUi } from "./swagger.js";
import authRoutes from "./routes/auth.js";
import aiRoutes from "./routes/ai.js";
import { errorHandler } from "./middleware/error.js";

const app = express();

// Security headers
app.use(helmet());

// CORS - restrict in production via env
const allowedOrigins = (process.env.CORS_ORIGIN || "http://localhost:3000")
  .split(",")
  .map((o) => o.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, curl) in dev; restrict in prod
      if (!origin) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      return callback(new Error("Not allowed by CORS"));
    },
    credentials: true,
  })
);

// Body parsing with limits
app.use(express.json({ limit: "10kb" }));
app.use(express.urlencoded({ extended: true, limit: "10kb" }));

// Rate limiting for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // limit each IP to 10 requests per windowMs for auth
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests, please try again later." },
});

// Rate limiting for AI endpoints
const aiLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 20, // limit each IP to 20 AI requests per hour
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many AI requests, please try again later." },
});

app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));

app.get("/api/health", (_req, res) => {
  res.status(200).json({
    status: "ok",
    service: "personal-secretary-api",
  });
});

app.use("/api/auth", authLimiter, authRoutes);
app.use("/api/ai", aiLimiter, aiRoutes);
app.use(errorHandler);

export default app;
