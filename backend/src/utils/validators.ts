import { z } from "zod";

const email = z
  .string()
  .trim()
  .toLowerCase()
  .min(3)
  .max(254)
  .email("Enter a valid email address");

const password = z
  .string()
  .min(8, "Password must be at least 8 characters")
  .max(128, "Password must be at most 128 characters");

const name = z.string().trim().max(80, "Name must be at most 80 characters");

// `captchaToken` is optional in the schema because CAPTCHA can be disabled in
// local development. When CAPTCHA_ENABLED=true the middleware enforces it.
const captchaToken = z.string().max(4096).optional();

export const signupSchema = z.object({
  body: z.object({
    name: name.optional(),
    email,
    password,
    captchaToken,
  }),
});

export const loginSchema = z.object({
  body: z.object({
    email,
    password: z.string().min(1, "Password is required").max(128),
    captchaToken,
  }),
});

export const chatSchema = z.object({
  body: z.object({
    message: z
      .string()
      .trim()
      .min(1, "Message is required")
      .max(1000, "Message must be at most 1000 characters"),
  }),
});
