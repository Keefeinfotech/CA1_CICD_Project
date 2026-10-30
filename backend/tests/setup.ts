process.env.NODE_ENV = "test";
process.env.JWT_SECRET = "test-only-secret-value-1234567890";
process.env.BCRYPT_ROUNDS = "10";
// Keep rate limits out of the way in tests unless a test opts in.
process.env.AUTH_RATE_LIMIT_MAX = "1000";
process.env.AI_RATE_LIMIT_PER_USER = "1000";
