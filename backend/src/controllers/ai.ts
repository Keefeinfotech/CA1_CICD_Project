import { NextFunction, Request, Response } from "express";
import { AppError } from "../utils/AppError.js";

const AI_PROVIDER = process.env.AI_PROVIDER || "mock";
const AI_MODEL = process.env.AI_MODEL || "mock-model";

export const chat = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const { message } = req.body as { message: string };

    if (AI_PROVIDER === "mock") {
      return res.status(200).json({
        reply: `Auxilia AI (mock): I received your message: "${message}". Configure AI_PROVIDER and API keys for real responses.`,
        provider: AI_PROVIDER,
        model: AI_MODEL,
      });
    }

    return next(
      new AppError(501, "NOT_IMPLEMENTED", "AI provider is not implemented")
    );
  } catch (err) {
    return next(err);
  }
};
