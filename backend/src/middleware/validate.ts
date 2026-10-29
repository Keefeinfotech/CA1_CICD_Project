import { NextFunction, Request, Response } from "express";
import { ZodError, type ZodTypeAny } from "zod";

interface FieldIssue {
  path: string;
  message: string;
}

const toFieldIssues = (error: ZodError): FieldIssue[] =>
  error.issues.map((issue) => ({
    path: issue.path.join("."),
    message: issue.message,
  }));

export const validate =
  (schema: ZodTypeAny) =>
  (req: Request, res: Response, next: NextFunction) => {
    try {
      const parsed = schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      });

      if (parsed && typeof parsed === "object" && "body" in parsed) {
        req.body = parsed.body;
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
