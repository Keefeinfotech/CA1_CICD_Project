import request from "supertest";
import { beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("../../src/models/User.js", () => ({
  User: {
    findById: vi.fn(),
  },
}));

import app from "../../src/app";
import { User } from "../../src/models/User.js";
import { signAccessToken } from "../../src/utils/tokens";

const userModel = User as any;

beforeEach(() => {
  vi.clearAllMocks();
});

// Builds a token and a matching user document so single-session checks pass.
const authenticate = (): string => {
  const { token, sessionId } = signAccessToken("user-1", "ada@example.com");
  userModel.findById.mockReturnValue({
    lean: vi.fn().mockResolvedValue({
      _id: "user-1",
      email: "ada@example.com",
      activeSessionId: sessionId,
      activeSessionExpiresAt: new Date(Date.now() + 60 * 60 * 1000),
    }),
  });
  return token;
};

describe("POST /api/ai/chat", () => {
  it("requires authentication", async () => {
    const res = await request(app)
      .post("/api/ai/chat")
      .send({ message: "hello" });

    expect(res.status).toBe(401);
    expect(res.body.code).toBe("UNAUTHORIZED");
  });

  it("rejects an invalid token", async () => {
    const res = await request(app)
      .post("/api/ai/chat")
      .set("Authorization", "Bearer not-a-real-token")
      .send({ message: "hello" });

    expect(res.status).toBe(401);
  });

  it("returns a reply for an authenticated user", async () => {
    const token = authenticate();

    const res = await request(app)
      .post("/api/ai/chat")
      .set("Authorization", `Bearer ${token}`)
      .send({ message: "  hello  " });

    expect(res.status).toBe(200);
    expect(res.body.reply).toContain("hello");
    expect(res.body.provider).toBe("mock");
  });

  it("validates the message after authentication", async () => {
    const token = authenticate();

    const res = await request(app)
      .post("/api/ai/chat")
      .set("Authorization", `Bearer ${token}`)
      .send({ message: "   " });

    expect(res.status).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");
  });
});

describe("unknown routes", () => {
  it("return a structured 404", async () => {
    const res = await request(app).get("/api/does-not-exist");
    expect(res.status).toBe(404);
    expect(res.body.code).toBe("NOT_FOUND");
  });
});
