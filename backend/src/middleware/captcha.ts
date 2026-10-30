import { NextFunction, Request, Response } from "express";
import { isCaptchaEnabled, verifyTurnstileToken } from "../utils/captcha.js";

/**
 * Enforces a CAPTCHA on authentication endpoints when CAPTCHA_ENABLED=true.
 *
 * Design notes:
 * - Disabled by default so local development and CI do not need Cloudflare keys.
 * - The token can be sent in the JSON body (`captchaToken`) or as the
 *   `X-Captcha-Token` header, which keeps it out of URL/logs.
 * - A missing server secret is a misconfiguration (503), not a client error.
 */
export const requireCaptcha = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  if (!isCaptchaEnabled()) {
    return next();
  }

  if (!process.env.TURNSTILE_SECRET_KEY?.trim()) {
    return res.status(503).json({
      error: "CAPTCHA is enabled but not configured",
      code: "CAPTCHA_NOT_CONFIGURED",
    });
  }

  const headerToken = req.headers["x-captcha-token"];
  const token =
    (typeof headerToken === "string" ? headerToken : undefined) ||
    (typeof req.body?.captchaToken === "string" ? req.body.captchaToken : "");

  if (!token) {
    return res.status(400).json({
      error: "CAPTCHA verification is required",
      code: "CAPTCHA_REQUIRED",
    });
  }

  const result = await verifyTurnstileToken(token, req.ip);
  if (!result.success) {
    console.warn(`[security] CAPTCHA rejected: ${result.reason}`);
    return res.status(400).json({
      error: "CAPTCHA verification failed",
      code: "CAPTCHA_FAILED",
    });
  }

  return next();
};
