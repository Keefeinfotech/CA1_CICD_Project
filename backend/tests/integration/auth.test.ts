
/*
 * File Name: auth.test.ts
 * Description: Integration tests for user authentication endpoints.
 * Author: Keefe Chen
 */

import bcrypt from "bcryptjs";
import request from "supertest";
import { beforeEach, describe, expect, it, vi } from "vitest";

// Mock the User model to prevent tests from accessing the actual database.
vi.mock("../../src/models/User.js", () => ({
  User: {
    findOne: vi.fn(),
    create: vi.fn(),
    findById: vi.fn(),
  },
}));

import app from "../../src/app";
import { User } from "../../src/models/User.js";
import { verifyAccessToken } from "../../src/utils/tokens";

// Access mocked User model methods.
const userModel = User as any;

// Simulate a Mongoose query supporting .select().
const selectResult = (value: unknown) => ({
  select: vi.fn().mockResolvedValue(value),
});

// Shared test password and its hash.
const password = "password123";
const passwordHashPromise = bcrypt.hash(password, 10);

// Reset mock call history before each test.
beforeEach(() => {
  vi.clearAllMocks();
});

// ==========================================
// SIGNUP TESTS
// ==========================================

describe("POST /api/auth/signup", () => {
  it("creates an account and returns a signed session token", async () => {
    userModel.findOne.mockResolvedValue(null);

    // Mock the newly created user document.
    const created = {
      _id: "user-1",
      name: "Ada",
      email: "ada@example.com",
      activeSessionId: null as string | null,
      save: vi.fn().mockResolvedValue(undefined),
    };

    userModel.create.mockResolvedValue(created);

    const res = await request(app)
      .post("/api/auth/signup")
      .send({
        name: "  Ada  ",
        email: "  ADA@Example.COM ",
        password,
      });

    // Verify successful account creation.
    expect(res.status).toBe(201);

    expect(res.body.user).toEqual({
      id: "user-1",
      name: "Ada",
      email: "ada@example.com",
    });

    // Verify that the user data was normalised.
    expect(userModel.create).toHaveBeenCalledWith(
      expect.objectContaining({
        email: "ada@example.com",
        name: "Ada",
      })
    );

    // Verify the access token.
    const payload = verifyAccessToken(res.body.token);

    expect(payload?.sub).toBe("user-1");

    // Verify that the token becomes the user's active session.
    expect(created.activeSessionId).toBe(payload?.jti);
    expect(created.save).toHaveBeenCalledTimes(1);
  });

  it("rejects an email that is already registered", async () => {
    userModel.findOne.mockResolvedValue({
      _id: "existing",
    });

    const res = await request(app)
      .post("/api/auth/signup")
      .send({
        email: "ada@example.com",
        password,
      });

    expect(res.status).toBe(409);
    expect(res.body.code).toBe("CONFLICT");

    // Ensure that no new account was created.
    expect(userModel.create).not.toHaveBeenCalled();
  });

  it("rejects invalid input without echoing values", async () => {
    const res = await request(app)
      .post("/api/auth/signup")
      .send({
        email: "not-an-email",
        password: "secret-should-not-appear",
      });

    expect(res.status).toBe(400);
    expect(res.body.code).toBe("VALIDATION_ERROR");

    // Ensure sensitive input is not returned in the response.
    expect(JSON.stringify(res.body)).not.toContain(
      "secret-should-not-appear"
    );
  });

  it("rejects malformed JSON bodies", async () => {
    const res = await request(app)
      .post("/api/auth/signup")
      .set("Content-Type", "application/json")
      .send('{"email": ');

    expect(res.status).toBe(400);
    expect(res.body.code).toBe("INVALID_JSON");
  });
});

// ==========================================
// LOGIN TESTS
// ==========================================

describe("POST /api/auth/login", () => {
  it("returns a token and records the login time", async () => {
    const save = vi.fn().mockResolvedValue(undefined);

    const user = {
      _id: "user-1",
      name: "Ada",
      email: "ada@example.com",
      passwordHash: await passwordHashPromise,
      lastLoginAt: null as Date | null,
      activeSessionId: null as string | null,
      save,
    };

    userModel.findOne.mockReturnValue(selectResult(user));

    const res = await request(app)
      .post("/api/auth/login")
      .send({
        email: "ADA@example.com",
        password,
      });

    expect(res.status).toBe(200);
    expect(res.body.user.email).toBe("ada@example.com");

    // Verify the returned access token.
    expect(verifyAccessToken(res.body.token)?.email).toBe(
      "ada@example.com"
    );

    // Verify that the login timestamp was updated.
    expect(save).toHaveBeenCalledTimes(1);
    expect(user.lastLoginAt).toBeInstanceOf(Date);
  });

  it("rejects a wrong password", async () => {
    userModel.findOne.mockReturnValue(
      selectResult({
        _id: "user-1",
        email: "ada@example.com",
        passwordHash: await passwordHashPromise,
        save: vi.fn(),
      })
    );

    const res = await request(app)
      .post("/api/auth/login")
      .send({
        email: "ada@example.com",
        password: "wrong-password",
      });

    expect(res.status).toBe(401);
    expect(res.body.code).toBe("UNAUTHORIZED");
  });

  it("rejects an unknown account with the same message", async () => {
    userModel.findOne.mockReturnValue(selectResult(null));

    const res = await request(app)
      .post("/api/auth/login")
      .send({
        email: "nobody@example.com",
        password,
      });

    expect(res.status).toBe(401);
    expect(res.body.error).toBe("Invalid email or password");
  });
});
