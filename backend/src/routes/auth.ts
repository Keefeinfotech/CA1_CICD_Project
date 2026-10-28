import { Router } from "express";
import { signup, login } from "../controllers/auth.js";
import { validate } from "../middleware/validate.js";
import { signupSchema, loginSchema } from "../utils/validators.js";

const router = Router();

router.post("/signup", validate(signupSchema), signup);
router.post("/login", validate(loginSchema), login);

export default router;
