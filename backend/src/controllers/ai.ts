import { Request, Response } from "express";

const AI_PROVIDER = process.env.AI_PROVIDER || "mock";
const AI_MODEL = process.env.AI_MODEL || "mock-model";

export const chat = async (req: Request, res: Response) => {
  try {
    const { message } = req.body || {};

    if (!message || typeof message !== "string") {
      return res.status(400).json({ error: "Message is required" });
    }
    if (message.length > 1000) {
      return res.status(400).json({ error: "Message too long" });
    }

    // Mock provider for dev/testing - replace with real provider in prod
    if (AI_PROVIDER === "mock") {
      return res.status(200).json({
        reply: `Auxilia AI (mock): I received your message: "${message}". Configure AI_PROVIDER and API keys for real responses.`,
        provider: AI_PROVIDER,
        model: AI_MODEL,
      });
    }

    // Placeholder for real providers
    return res.status(501).json({ error: "AI provider not implemented" });
  } catch (err) {
    return res.status(500).json({ error: "Internal server error" });
  }
};
