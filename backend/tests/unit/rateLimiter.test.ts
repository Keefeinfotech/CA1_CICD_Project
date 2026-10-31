import express from "express";
import request from "supertest";
import { afterEach, describe, expect, it, vi } from "vitest";
import { createRateLimiter } from "../../src/middleware/rateLimiter";
import { requestId } from "../../src/middleware/requestId";

afterEach(() => {
  vi.restoreAllMocks();
});

describe("rate limiter factory", () => {
  it("returns a structured 429 after the limit is exceeded", async () => {
    vi.spyOn(console, "warn").mockImplementation(() => undefined);

    const app = express();
    app.use(requestId);
    app.use(
      createRateLimiter({
        name: "test",
        windowMs: 60_000,
        limit: 1,
        message: { error: "Too many requests, please try again later." },
      })
    );
    app.get("/", (_req, res) => {
      res.status(200).json({ ok: true });
    });

    const first = await request(app).get("/");
    const second = await request(app).get("/");

    expect(first.status).toBe(200);
    expect(second.status).toBe(429);
    expect(second.body).toEqual({
      error: "Too many requests, please try again later.",
    });
  });
});
