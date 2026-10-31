import { Router } from "express";

import {
  createTask,
  getTasks,
  getTaskById,
  updateTask,
  deleteTask,
} from "../controllers/task.controller.js";

import { requireAuth } from "../middleware/auth.js";
import { authorize } from "../middleware/authorize.js";

const router = Router();

// Require authentication for all task endpoints.
router.use(requireAuth);

// Retrieve tasks.
router.get("/", getTasks);
router.get("/:taskId", getTaskById);

// Create, update and delete tasks.
router.post("/", authorize("ADMIN", "GROUP_OWNER"), createTask);
router.patch("/:taskId", authorize("ADMIN", "GROUP_OWNER"), updateTask);
router.delete("/:taskId", authorize("ADMIN", "GROUP_OWNER"), deleteTask);

export default router;