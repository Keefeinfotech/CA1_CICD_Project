import { Router } from "express";
import { chat } from "../controllers/ai.js";

const router = Router();

router.post("/chat", chat);

export default router;
