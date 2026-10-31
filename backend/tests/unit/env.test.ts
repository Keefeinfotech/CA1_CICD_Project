import { afterEach, describe, expect, it } from "vitest";
import {
  allowConcurrentSessions,
  assertRuntimeEnv,
  EnvError,
  getAiModel,
  getAiProvider,
  getAiRateLimitPerUser,
  getAuthRateLimitMax,
  getBcryptRounds,
  getCorsOrigins,
  getJwtExpiresIn,
  getJwtSecret,
  getMongoUri,
  getPort,
  isProduction,
  isTest,
  shouldTrustProxy,
} from "../../src/config/environment";

const keys = [
  "NODE_ENV",
  "JWT_SECRET",
  "BCRYPT_ROUNDS",
  "JWT_EXPIRES_IN",
  "ALLOW_CONCURRENT_SESSIONS",
  "PORT",
  "CORS_ORIGIN",
  "AUTH_RATE_LIMIT_MAX",
  "AI_RATE_LIMIT_PER_USER",
  "AI_PROVIDER",
  "AI_MODEL",
  "TRUST_PROXY",
  "MONGODB_URI",
  "CAPTCHA_ENABLED",
  "TURNSTILE_SECRET_KEY",
] as const;

const original = Object.fromEntries(
  keys.map((key) => [key, process.env[key]])
);

afterEach(() => {
  for (const key of keys) {
    const value = original[key];
    if (value === undefined) {
      delete process.env[key];
    } else {
      process.env[key] = value;
    }
  }
});

describe("environment configuration", () => {
  it("returns the configured JWT secret", () => {
    process.env.JWT_SECRET = "a-secret-that-is-long-enough";
    expect(getJwtSecret()).toBe("a-secret-that-is-long-enough");
  });

  it("rejects a missing JWT secret", () => {
    delete process.env.JWT_SECRET;
    expect(() => getJwtSecret()).toThrow(EnvError);
  });

  it("rejects a short JWT secret", () => {
    process.env.JWT_SECRET = "too-short";
    expect(() => getJwtSecret()).toThrow(EnvError);
  });

  it("defaults the token expiry when unset", () => {
    delete process.env.JWT_EXPIRES_IN;
    expect(getJwtExpiresIn()).toBe("1d");
  });

  it("clamps bcrypt rounds to a safe range", () => {
    process.env.BCRYPT_ROUNDS = "999";
    expect(getBcryptRounds()).toBe(15);

    process.env.BCRYPT_ROUNDS = "1";
    expect(getBcryptRounds()).toBe(10);

    process.env.BCRYPT_ROUNDS = "not-a-number";
    expect(getBcryptRounds()).toBe(10);
  });

  it("only allows concurrent sessions when explicitly enabled", () => {
    delete process.env.ALLOW_CONCURRENT_SESSIONS;
    expect(allowConcurrentSessions()).toBe(false);
    process.env.ALLOW_CONCURRENT_SESSIONS = "true";
    expect(allowConcurrentSessions()).toBe(true);
  });

  it("validates and falls back for the port", () => {
    delete process.env.PORT;
    expect(getPort()).toBe(3000);
    process.env.PORT = "8080";
    expect(getPort()).toBe(8080);
    process.env.PORT = "nope";
    expect(getPort()).toBe(3000);
  });

  it("parses a CORS allow-list", () => {
    process.env.CORS_ORIGIN = " https://app.example.com , http://localhost:5173 ";
    expect(getCorsOrigins()).toEqual([
      "https://app.example.com",
      "http://localhost:5173",
    ]);
  });

  it("uses sensible rate-limit defaults", () => {
    delete process.env.AUTH_RATE_LIMIT_MAX;
    delete process.env.AI_RATE_LIMIT_PER_USER;
    expect(getAuthRateLimitMax()).toBe(10);
    expect(getAiRateLimitPerUser()).toBe(20);
  });

  it("uses provider defaults", () => {
    delete process.env.AI_PROVIDER;
    delete process.env.AI_MODEL;
    expect(getAiProvider()).toBe("mock");
    expect(getAiModel()).toBe("mock-model");
  });

  it("normalises infrastructure flags", () => {
    process.env.TRUST_PROXY = "true";
    expect(shouldTrustProxy()).toBe(true);
    delete process.env.MONGODB_URI;
    expect(getMongoUri()).toBeNull();
    process.env.MONGODB_URI = " mongodb://localhost:27017/auxilia ";
    expect(getMongoUri()).toBe("mongodb://localhost:27017/auxilia");
  });

  it("detects the runtime mode", () => {
    process.env.NODE_ENV = "production";
    expect(isProduction()).toBe(true);
    expect(isTest()).toBe(false);
    process.env.NODE_ENV = "test";
    expect(isProduction()).toBe(false);
    expect(isTest()).toBe(true);
  });

  it("fails closed when CAPTCHA is enabled without a secret", () => {
    process.env.CAPTCHA_ENABLED = "true";
    delete process.env.TURNSTILE_SECRET_KEY;
    expect(() => assertRuntimeEnv()).toThrow(EnvError);
  });

  it("requires CAPTCHA and CORS in production", () => {
    process.env.NODE_ENV = "production";
    process.env.CAPTCHA_ENABLED = "false";
    expect(() => assertRuntimeEnv()).toThrow(EnvError);

    process.env.CAPTCHA_ENABLED = "true";
    process.env.TURNSTILE_SECRET_KEY = "secret";
    delete process.env.CORS_ORIGIN;
    expect(() => assertRuntimeEnv()).toThrow(EnvError);

    process.env.CORS_ORIGIN = "https://app.example.com";
    expect(() => assertRuntimeEnv()).not.toThrow();
  });
});
