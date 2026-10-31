import type { NextFunction, Request, Response } from "express";
import { ZodError, type ZodType } from "zod";

interface FieldIssue {
  path: string;
  message: string;
}

const toFieldIssues = (error: ZodError): FieldIssue[] =>
  error.issues.map((issue) => ({
    path: issue.path.join("."),
    message: issue.message,
  }));

export const validateRequest =
  (schema: ZodType) =>
  (req: Request, res: Response, next: NextFunction) => {
    try {
      const parsed = schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      }) as {
        body?: unknown;
        query?: unknown;
        params?: unknown;
      };

      if (parsed.body !== undefined) req.body = parsed.body;
      if (parsed.params !== undefined) {
        req.params = parsed.params as Request["params"];
      }
      if (parsed.query !== undefined) {
        Object.defineProperty(req, "query", {
          value: parsed.query,
          writable: true,
          configurable: true,
        });
      }

      return next();
    } catch (err) {
      if (err instanceof ZodError) {
        return res.status(400).json({
          error: "Validation failed",
          code: "VALIDATION_ERROR",
          details: toFieldIssues(err),
        });
      }
      return next(err);
    }
  };
