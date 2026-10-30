import express from "express";
import cors from "cors";
import helmet from "helmet";
import rateLimit from "express-rate-limit";
import { swaggerDocument, swaggerUi } from "./swagger.js";
import authRoutes from "./routes/auth.js";
import aiRoutes from "./routes/ai.js";
import { errorHandler, notFound } from "./middleware/error.js";

const app = express();

app.disable("x-powered-by");

// Behind a reverse proxy (Railway, Nginx, Cloudflare) trust the first hop so
// rate limiting and CAPTCHA see the real client IP instead of the proxy IP.
if (process.env.TRUST_PROXY === "true") {
  app.set("trust proxy", 1);
}

app.use(helmet());

const allowedOrigins = (
  process.env.CORS_ORIGIN || "http://localhost:3000,http://localhost:5173"
)
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(
  cors({
    // Explicit allow-list. Requests without an Origin header (native apps,
    // curl, server-to-server) are allowed; browsers always send one.
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      return callback(new Error("Origin not allowed by CORS"));
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "X-Captcha-Token"],
    maxAge: 600,
    optionsSuccessStatus: 204,
  })
);

app.use(express.json({ limit: "10kb" }));
app.use(express.urlencoded({ extended: true, limit: "10kb" }));

const configuredAuthLimit = Number(process.env.AUTH_RATE_LIMIT_MAX);
const authLimit =
  Number.isInteger(configuredAuthLimit) && configuredAuthLimit > 0
    ? configuredAuthLimit
    : 10;

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: authLimit,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests, please try again later." },
});

const configuredAiLimit = Number(process.env.AI_RATE_LIMIT_PER_USER);
const aiLimit =
  Number.isInteger(configuredAiLimit) && configuredAiLimit > 0
    ? configuredAiLimit
    : 20;

const aiLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: aiLimit,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many AI requests, please try again later." },
});

if (process.env.NODE_ENV !== "production") {
  app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));
}

app.get("/api/health", (_req, res) => {
  res.status(200).json({
    status: "ok",
    service: "personal-secretary-api",
  });
});

app.use("/api/auth", authLimiter, authRoutes);
app.use("/api/ai", aiLimiter, aiRoutes);

app.use(notFound);
app.use(errorHandler);

export default app;
