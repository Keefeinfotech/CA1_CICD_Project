import { Request, Response } from "express";
import bcrypt from "bcryptjs";
import { User } from "../models/User.js";
import { getBcryptRounds, getJwtExpiresIn } from "../config/env.js";
import { signAccessToken } from "../utils/tokens.js";
import { parseDurationToMs } from "../utils/session.js";
import { conflict, unauthorized } from "../utils/AppError.js";
import { requireUserId } from "../middleware/auth.js";

const SESSION_TTL_MS = 24 * 60 * 60 * 1000;

const sessionExpiry = (): Date => {
  const configured = parseDurationToMs(getJwtExpiresIn());
  return new Date(Date.now() + (configured ?? SESSION_TTL_MS));
};

export const signup = async (req: Request, res: Response) => {
  const { name, email, password } = req.body;

  const existing = await User.findOne({ email });
  if (existing) {
    throw conflict("Email already registered");
  }

  const passwordHash = await bcrypt.hash(password, getBcryptRounds());
  const user = await User.create({ name, email, passwordHash });

  // Auto-login after signup: the new account owns the only active session.
  const { token, sessionId } = signAccessToken(String(user._id), user.email);
  user.activeSessionId = sessionId;
  user.activeSessionExpiresAt = sessionExpiry();
  user.lastLoginAt = new Date();
  await user.save();

  return res.status(201).json({
    token,
    user: { id: user._id, name: user.name, email: user.email },
  });
};

export const login = async (req: Request, res: Response) => {
  const { email, password } = req.body;

  // passwordHash is select:false, so it must be requested explicitly.
  const user = await User.findOne({ email }).select("+passwordHash");
  if (!user) {
    throw unauthorized("Invalid email or password");
  }

  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) {
    throw unauthorized("Invalid email or password");
  }

  const { token, sessionId } = signAccessToken(
    String(user._id),
    user.email
  );

  // Record the newest session. Any older token is now invalid unless
  // concurrent sessions are explicitly allowed (checked in requireAuth).
  user.activeSessionId = sessionId;
  user.activeSessionExpiresAt = sessionExpiry();
  user.lastLoginAt = new Date();
  await user.save();

  return res.status(200).json({
    token,
    user: { id: user._id, name: user.name, email: user.email },
  });
};

export const logout = async (req: Request, res: Response) => {
  const userId = requireUserId(req);
  await User.updateOne(
    { _id: userId },
    { $set: { activeSessionId: null, activeSessionExpiresAt: null } }
  );
  return res.status(204).send();
};

export const me = async (req: Request, res: Response) => {
  const userId = requireUserId(req);
  const user = await User.findById(userId).lean();
  if (!user) {
    throw unauthorized("Invalid or expired session");
  }
  return res.status(200).json({
    user: { id: user._id, name: user.name, email: user.email },
  });
};
