import { z } from "zod";

export const chatSchema = z.object({
  body: z
    .object({
      message: z
        .string()
        .trim()
        .min(1, "Message is required")
        .max(1000, "Message must be at most 1000 characters"),
    })
    .strict(),
});
