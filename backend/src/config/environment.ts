export class EnvError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "EnvError";
  }
}

const MIN_JWT_SECRET_LENGTH = 16;

export const isProduction = (): boolean =>
  process.env.NODE_ENV === "production";

export const isTest = (): boolean => process.env.NODE_ENV === "test";

export const getJwtSecret = (): string => {
  const secret = process.env.JWT_SECRET?.trim();
  if (!secret || secret.length < MIN_JWT_SECRET_LENGTH) {
    throw new EnvError(
      `JWT_SECRET must be set to at least ${MIN_JWT_SECRET_LENGTH} characters`
    );
  }
  return secret;
};

export const getJwtExpiresIn = (): string =>
  process.env.JWT_EXPIRES_IN?.trim() || "1d";

export const getBcryptRounds = (): number => {
  const parsed = Number(process.env.BCRYPT_ROUNDS);
  if (!Number.isInteger(parsed)) {
    return 10;
  }
  return Math.min(Math.max(parsed, 10), 15);
};

export const allowConcurrentSessions = (): boolean =>
  process.env.ALLOW_CONCURRENT_SESSIONS === "true";

export const getPort = (): number => {
  const parsed = Number(process.env.PORT);
  if (!Number.isInteger(parsed) || parsed < 1 || parsed > 65535) {
    return 3000;
  }
  return parsed;
};

export const getCorsOrigins = (): string[] =>
  (process.env.CORS_ORIGIN || "http://localhost:3000,http://localhost:5173")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);

export const getAuthRateLimitMax = (): number => {
  const parsed = Number(process.env.AUTH_RATE_LIMIT_MAX);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : 10;
};

export const getAiRateLimitPerUser = (): number => {
  const parsed = Number(process.env.AI_RATE_LIMIT_PER_USER);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : 20;
};

export const getAiProvider = (): string =>
  process.env.AI_PROVIDER?.trim() || "mock";

export const getAiModel = (): string =>
  process.env.AI_MODEL?.trim() || "mock-model";

export const shouldTrustProxy = (): boolean =>
  process.env.TRUST_PROXY === "true";

export const getMongoUri = (): string | null =>
  process.env.MONGODB_URI?.trim() || null;

export const assertRuntimeEnv = (): void => {
  getJwtSecret();

  if (
    process.env.CAPTCHA_ENABLED === "true" &&
    !process.env.TURNSTILE_SECRET_KEY?.trim()
  ) {
    throw new EnvError(
      "CAPTCHA_ENABLED=true requires TURNSTILE_SECRET_KEY to be set"
    );
  }

  if (isProduction()) {
    if (process.env.CAPTCHA_ENABLED !== "true") {
      throw new EnvError("CAPTCHA_ENABLED must be 'true' in production");
    }
    if (!process.env.CORS_ORIGIN?.trim()) {
      throw new EnvError("CORS_ORIGIN must be set in production");
    }
  }
};
