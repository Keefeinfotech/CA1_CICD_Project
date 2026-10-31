import type { Request, Response } from "express";

export const notFound = (_req: Request, res: Response): void => {
  res.status(404).json({ error: "Resource not found", code: "NOT_FOUND" });
};
