export class EnvError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "EnvError";
  }
}

const MIN_JWT_SECRET_LENGTH = 16;

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

// Single-session enforcement is on unless explicitly disabled.
// Set ALLOW_CONCURRENT_SESSIONS=true to let one user stay logged in on
// multiple devices at once (each token is then independent).
export const allowConcurrentSessions = (): boolean =>
  process.env.ALLOW_CONCURRENT_SESSIONS === "true";

export const assertRuntimeEnv = (): void => {
  getJwtSecret();

  if (process.env.CAPTCHA_ENABLED === "true" && !process.env.TURNSTILE_SECRET_KEY?.trim()) {
    throw new EnvError(
      "CAPTCHA_ENABLED=true requires TURNSTILE_SECRET_KEY to be set"
    );
  }

  if (process.env.NODE_ENV === "production") {
    if (process.env.CAPTCHA_ENABLED !== "true") {
      throw new EnvError("CAPTCHA_ENABLED must be 'true' in production");
    }
    if (!process.env.CORS_ORIGIN?.trim()) {
      throw new EnvError("CORS_ORIGIN must be set in production");
    }
  }
};
