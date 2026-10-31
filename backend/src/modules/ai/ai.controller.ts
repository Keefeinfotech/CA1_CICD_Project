import type { NextFunction, Request, Response } from "express";
import { createChatReply } from "./ai.service.js";

export const chat = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  try {
    const { message } = req.body as { message: string };
    res.status(200).json(createChatReply(message));
  } catch (err) {
    next(err);
  }
};
