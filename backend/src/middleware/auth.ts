import { NextFunction, Request, Response } from "express";
import { User } from "../models/User.js";
import { allowConcurrentSessions } from "../config/env.js";
import { unauthorized } from "../utils/AppError.js";
import { isSessionActive } from "../utils/session.js";
import { verifyAccessToken } from "../utils/tokens.js";

export const requireAuth = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const header = req.headers.authorization;
    if (!header?.startsWith("Bearer ")) {
      return res.status(401).json({
        error: "Authentication required",
        code: "UNAUTHORIZED",
      });
    }

    const token = header.slice("Bearer ".length).trim();
    const payload = verifyAccessToken(token);
    if (!payload) {
      return res.status(401).json({
        error: "Invalid or expired session",
        code: "UNAUTHORIZED",
      });
    }

    const user = await User.findById(payload.sub).lean();
    if (!user) {
      return res.status(401).json({
        error: "Invalid or expired session",
        code: "UNAUTHORIZED",
      });
    }

    // Single-session enforcement: a newer login replaces older tokens.
    // Skip the check only when the operator explicitly allows concurrency.
    if (!allowConcurrentSessions() && !isSessionActive(user, payload.jti)) {
      return res.status(401).json({
        error: "Session ended. This account signed in on another device.",
        code: "SESSION_REPLACED",
      });
    }

    req.userId = String(user._id);
    req.userEmail = user.email;
    return next();
  } catch (err) {
    return next(err);
  }
};

export const requireUserId = (req: Request): string => {
  if (!req.userId) {
    throw unauthorized();
  }
  return req.userId;
};
