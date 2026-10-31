import type { Request } from "express";
import { unauthorized } from "./AppError.js";

export const requireUserId = (req: Request): string => {
  if (!req.userId) {
    throw unauthorized();
  }
  return req.userId;
};
