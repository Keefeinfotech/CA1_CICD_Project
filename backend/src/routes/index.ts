import { Router } from "express";

import authRoutes from "./auth.ts";
import aiRoutes from "./ai.ts";
import userRoutes from "./user.routes.ts";
import taskRoutes from "./task.routes.ts";
import roadmapRoutes from "./roadmap.routes.ts";
import rubricRoutes from "./rubric.routes.ts";
import feedbackRoutes from "./feedback.routes.ts";
import calendarRoutes from "./calendar.routes.ts";
import progressRoutes from "./progress.routes.ts";

// Group-related routes
import groupRoutes from "./groups/group.routes.ts";
import memberRoutes from "./groups/member.routes.ts";
import sessionRoutes from "./groups/session.routes.ts";

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