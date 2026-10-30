import { Router } from "express";
import { login, logout, me, signup } from "../controllers/auth.js";
import { requireAuth } from "../middleware/auth.js";
import { requireCaptcha } from "../middleware/captcha.js";
import { validate } from "../middleware/validate.js";
import { loginSchema, signupSchema } from "../utils/validators.js";

const router = Router();

// CAPTCHA is applied before validation so bots are rejected early.
router.post("/signup", requireCaptcha, validate(signupSchema), signup);
router.post("/login", requireCaptcha, validate(loginSchema), login);

// Session-aware endpoints.
router.get("/me", requireAuth, me);
router.post("/logout", requireAuth, logout);

export default router;
