import { Router } from "express";
import { chat } from "../controllers/ai.js";
import { requireAuth } from "../middleware/auth.js";
import { validate } from "../middleware/validate.js";
import { chatSchema } from "../utils/validators.js";

const router = Router();

router.post("/chat", requireAuth, validate(chatSchema), chat);

export default router;
