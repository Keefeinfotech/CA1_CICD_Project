import request from "supertest";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("../../src/models/User.js", () => ({
  User: {
    findById: vi.fn(),
    updateOne: vi.fn(),
  },
}));

import app from "../../src/app";
import { User } from "../../src/models/User.js";
import { signAccessToken } from "../../src/utils/tokens";

const userModel = User as any;

const withSession = (sessionId: string, overrides: Record<string, unknown> = {}) =>
  userModel.findById.mockReturnValue({
    lean: vi.fn().mockResolvedValue({
      _id: "user-1",
      name: "Ada",
      email: "ada@example.com",
      activeSessionId: sessionId,
      activeSessionExpiresAt: new Date(Date.now() + 60 * 60 * 1000),
      ...overrides,
    }),
  });

beforeEach(() => {
  vi.clearAllMocks();
});

afterEach(() => {
  delete process.env.CAPTCHA_ENABLED;
  delete process.env.TURNSTILE_SECRET_KEY;
});

describe("session enforcement", () => {
  it("rejects a request without a token", async () => {
    const res = await request(app).get("/api/auth/me");
    expect(res.status).toBe(401);
    expect(res.body.code).toBe("UNAUTHORIZED");
  });

  it("returns the current user for the active session", async () => {
    const { token, sessionId } = signAccessToken("user-1", "ada@example.com");
    withSession(sessionId);

    const res = await request(app)
      .get("/api/auth/me")
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.user.email).toBe("ada@example.com");
  });

  it("rejects a token replaced by a newer login", async () => {
    const { token } = signAccessToken("user-1", "ada@example.com");
    // The stored session id differs, as if another device logged in.
    withSession("session-from-another-device");

    const res = await request(app)
      .get("/api/auth/me")
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(401);
    expect(res.body.code).toBe("SESSION_REPLACED");
  });

  it("rejects an expired stored session", async () => {
    const { token, sessionId } = signAccessToken("user-1", "ada@example.com");
    withSession(sessionId, {
      activeSessionExpiresAt: new Date(Date.now() - 60_000),
    });

    const res = await request(app)
      .get("/api/auth/me")
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(401);
    expect(res.body.code).toBe("SESSION_REPLACED");
  });

  it("clears the session on logout", async () => {
    const { token, sessionId } = signAccessToken("user-1", "ada@example.com");
    withSession(sessionId);
    userModel.updateOne.mockResolvedValue({ acknowledged: true });

    const res = await request(app)
      .post("/api/auth/logout")
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(204);
    expect(userModel.updateOne).toHaveBeenCalledWith(
      { _id: "user-1" },
      { $set: { activeSessionId: null, activeSessionExpiresAt: null } }
    );
  });
});

describe("CAPTCHA enforcement", () => {
  it("requires a token when CAPTCHA is enabled", async () => {
    process.env.CAPTCHA_ENABLED = "true";
    process.env.TURNSTILE_SECRET_KEY = "test-secret";

    const res = await request(app)
      .post("/api/auth/login")
      .send({ email: "ada@example.com", password: "password123" });

    expect(res.status).toBe(400);
    expect(res.body.code).toBe("CAPTCHA_REQUIRED");
  });

  it("fails closed when CAPTCHA is enabled without a secret", async () => {
    process.env.CAPTCHA_ENABLED = "true";

    const res = await request(app)
      .post("/api/auth/login")
      .send({
        email: "ada@example.com",
        password: "password123",
        captchaToken: "token",
      });

    expect(res.status).toBe(503);
    expect(res.body.code).toBe("CAPTCHA_NOT_CONFIGURED");
  });

  it("is skipped when CAPTCHA is disabled (local development)", async () => {
    process.env.CAPTCHA_ENABLED = "false";

    // Validation runs after CAPTCHA, so a malformed body proves it was skipped.
    const res = await request(app)
      .post("/api/auth/login")
      .send({ email: "not-an-email", password: "x" });

    expect(res.status).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
  });
});
