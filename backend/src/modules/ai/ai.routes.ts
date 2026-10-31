import { Router } from "express";
import { authenticate } from "../../middleware/authenticate.js";
import { aiRateLimiter } from "../../middleware/rateLimiter.js";
import { validateRequest } from "../../middleware/validateRequest.js";
import { chat } from "./ai.controller.js";
import { chatSchema } from "./ai.validation.js";

const router = Router();

router.post("/chat", authenticate, aiRateLimiter, validateRequest(chatSchema), chat);

export default router;
