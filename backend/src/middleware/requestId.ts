import { randomUUID } from "node:crypto";
import type { NextFunction, Request, Response } from "express";

const REQUEST_ID_PATTERN = /^[A-Za-z0-9._:-]{1,100}$/;

const resolveRequestId = (req: Request): string => {
  const incoming = req.headers["x-request-id"];
  if (
    typeof incoming === "string" &&
    REQUEST_ID_PATTERN.test(incoming.trim())
  ) {
    return incoming.trim();
  }
  return randomUUID();
};

export const requestId = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  req.requestId = resolveRequestId(req);
  res.setHeader("X-Request-Id", req.requestId);
  next();
};
