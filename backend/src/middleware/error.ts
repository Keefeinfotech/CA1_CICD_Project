import { NextFunction, Request, Response } from "express";
import { AppError } from "../utils/AppError.js";

interface BodyParserError extends Error {
  type?: string;
  status?: number;
}

export const notFound = (_req: Request, res: Response) => {
  res.status(404).json({ error: "Resource not found", code: "NOT_FOUND" });
};

export const errorHandler = (
  err: unknown,
  req: Request,
  res: Response,
  _next: NextFunction
) => {
  if (res.headersSent) {
    return;
  }

  const parserError = err as BodyParserError;
  if (parserError?.type === "entity.parse.failed") {
    res.status(400).json({
      error: "Request body must be valid JSON",
      code: "INVALID_JSON",
    });
    return;
  }

  // The CORS middleware rejects disallowed browser origins by calling next(err).
  // Surface that as a 403 instead of a generic 500.
  if (err instanceof Error && err.message === "Origin not allowed by CORS") {
    res.status(403).json({
      error: "Origin not allowed",
      code: "CORS_FORBIDDEN",
    });
    return;
  }

  if (err instanceof AppError) {
    res.status(err.status).json({
      error: err.message,
      code: err.code,
      ...(err.details === undefined ? {} : { details: err.details }),
    });
    return;
  }

  const message = err instanceof Error ? err.message : "Unknown error";
  console.error(`[error] ${req.method} ${req.path}: ${message}`);

  res.status(500).json({
    error: "Internal server error",
    code: "INTERNAL_ERROR",
  });
};
