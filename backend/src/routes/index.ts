import { Router } from "express";

import authRoutes from "./auth.js";
import aiRoutes from "./ai.js";
import userRoutes from "./user.routes.js";
import taskRoutes from "./task.routes.js";
import roadmapRoutes from "./roadmap.routes.js";
import rubricRoutes from "./rubric.routes.js";
import feedbackRoutes from "./feedback.routes.js";
import calendarRoutes from "./calendar.routes.js";
import progressRoutes from "./progress.routes.js";

// Group-related routes
import groupRoutes from "./groups/group.routes.js";
import memberRoutes from "./groups/member.routes.js";
import sessionRoutes from "./groups/session.routes.js";

const router = Router();

router.use("/auth", authRoutes);
router.use("/ai", aiRoutes);
router.use("/users", userRoutes);
router.use("/tasks", taskRoutes);
router.use("/roadmaps", roadmapRoutes);
router.use("/rubrics", rubricRoutes);
router.use("/feedback", feedbackRoutes);
router.use("/calendar", calendarRoutes);
router.use("/progress", progressRoutes);

// Group-related routes
router.use("/groups", groupRoutes);
router.use("/groups/:groupId/members", memberRoutes);
router.use("/groups/:groupId/sessions", sessionRoutes);

export default router;