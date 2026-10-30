/**
 * File Name: app.ts
 * Description: Configures the Express application, security middleware,
 *              API routes, rate limiting, and error handling.
 * Author: Keefe Chen
 */

import express from "express";
import cors from "cors";
import helmet from "helmet";
import hpp from "hpp";
import compression from "compression";
import rateLimit from "express-rate-limit";

import { swaggerDocument, swaggerUi } from "./swagger.js";

// Route imports
import authRoutes from "./routes/auth.js";
import aiRoutes from "./routes/ai.js";
import userRoutes from "./routes/user.routes.js";
import taskRoutes from "./routes/task.routes.js";
import groupRoutes from "./routes/group.routes.js";
import roadmapRoutes from "./routes/roadmap.routes.js";
import rubricRoutes from "./routes/rubric.routes.js";
import feedbackRoutes from "./routes/feedback.routes.js";
import calendarRoutes from "./routes/calendar.routes.js";
import sessionRoutes from "./routes/session.routes.js";
import progressRoutes from "./routes/progress.routes.js";

// Error handling
import { errorHandler, notFound } from "./middleware/error.js";

const app = express();

// --------------------------------------------------
// 1. Core Server & Proxy Configuration
// --------------------------------------------------

// Disable identity headers
app.disable("x-powered-by");

// Express needs to trust reverse proxies (e.g. Nginx, Cloudflare, AWS ALB)
// to accurately capture client IPs for rate limiters.
if (process.env.TRUST_PROXY === "true") {
  app.set("trust proxy", 1);
}

// Enable response compression (gzip/deflate)
app.use(compression());

// --------------------------------------------------
// 2. Security Middleware
// --------------------------------------------------

// Set secure HTTP headers with Helmet
app.use(
  helmet({
    contentSecurityPolicy: process.env.NODE_ENV === "production",
    crossOriginResourcePolicy: { policy: "cross-origin" },
  })
);

// Prevent HTTP Parameter Pollution attacks (e.g., ?id=1&id=2)
app.use(hpp());

// CORS configuration with dynamic origin verification
const allowedOrigins = (
  process.env.CORS_ORIGIN ||
  "http://localhost:3000,http://localhost:5173"
)
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests without browser Origin headers (e.g., server-to-server, Postman)
      if (!origin) return callback(null, true);

      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }

      return callback(new Error("Origin not allowed by CORS"));
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: [
      "Content-Type",
      "Authorization",
      "X-Captcha-Token",
    ],
    maxAge: 600,
    optionsSuccessStatus: 204,
  })
);

// --------------------------------------------------
// 3. Request Body Parsing
// --------------------------------------------------

app.use(express.json({ limit: "10kb" }));
app.use(express.urlencoded({ extended: true, limit: "10kb" }));

// --------------------------------------------------
// 4. Global & Specific Rate Limiters
// --------------------------------------------------

// Global Rate Limiter: Protects against general DoS/brute-force sweeps across all routes
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: "Too many requests from this IP, please try again later.",
  },
});
app.use(globalLimiter);

// Authentication rate limiter
const configuredAuthLimit = Number(process.env.AUTH_RATE_LIMIT_MAX);
const authLimit =
  Number.isInteger(configuredAuthLimit) && configuredAuthLimit > 0
    ? configuredAuthLimit
    : 10;

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: authLimit,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: "Too many authentication attempts, please try again later.",
  },
});

// AI endpoints rate limiter
const configuredAiLimit = Number(process.env.AI_RATE_LIMIT_PER_USER);
const aiLimit =
  Number.isInteger(configuredAiLimit) && configuredAiLimit > 0
    ? configuredAiLimit
    : 20;

const aiLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: aiLimit,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: "Too many AI requests, please try again later.",
  },
});

// --------------------------------------------------
// 5. System Routes (Health & Documentation)
// --------------------------------------------------

app.get("/api/health", (_req, res) => {
  res.status(200).json({
    status: "ok",
    service: "auxilia-api",
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

if (process.env.NODE_ENV !== "production") {
  app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));
}

// --------------------------------------------------
// 6. Application API Routes
// --------------------------------------------------

app.use("/api/auth", authLimiter, authRoutes);
app.use("/api/ai", aiLimiter, aiRoutes);

app.use("/api/users", userRoutes);
app.use("/api/tasks", taskRoutes);
app.use("/api/groups", groupRoutes);

// Nested resource sub-routes under /api/groups
app.use("/api/groups/:groupId/roadmap", roadmapRoutes);
app.use("/api/groups/:groupId/rubrics", rubricRoutes);
app.use("/api/groups/:groupId/feedback", feedbackRoutes);
app.use("/api/groups/:groupId/sessions", sessionRoutes);
app.use("/api/groups/:groupId/progress", progressRoutes);

app.use("/api/calendar", calendarRoutes);

// --------------------------------------------------
// 7. Global Error Handling
// --------------------------------------------------

app.use(notFound);
app.use(errorHandler);

export default app;