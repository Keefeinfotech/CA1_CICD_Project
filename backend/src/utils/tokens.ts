import { randomUUID } from "node:crypto";
import jwt, { type JwtPayload, type SignOptions } from "jsonwebtoken";
import { getJwtExpiresIn, getJwtSecret } from "../config/env.js";

export interface AccessTokenPayload extends JwtPayload {
  sub: string;
  email: string;
  jti: string;
}

export interface SignedAccessToken {
  token: string;
  // The JWT id doubles as the session id for single-session enforcement.
  sessionId: string;
}

export const signAccessToken = (
  userId: string,
  email: string,
  sessionId: string = randomUUID()
): SignedAccessToken => {
  const options = {
    subject: userId,
    jwtid: sessionId,
    expiresIn: getJwtExpiresIn(),
    issuer: "auxilia-api",
  } as SignOptions;

  const token = jwt.sign({ email }, getJwtSecret(), options);
  return { token, sessionId };
};

export const verifyAccessToken = (token: string): AccessTokenPayload | null => {
  try {
    const payload = jwt.verify(token, getJwtSecret(), {
      issuer: "auxilia-api",
    });

    if (
      typeof payload === "string" ||
      typeof payload.sub !== "string" ||
      typeof payload.email !== "string" ||
      typeof payload.jti !== "string"
    ) {
      return null;
    }

    return payload as AccessTokenPayload;
  } catch {
    return null;
  }
};
