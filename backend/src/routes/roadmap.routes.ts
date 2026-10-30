
/**
 * File Name: roadmap.routes.ts
 * Description: Defines API endpoints for roadmap and milestone management.
 * Author: Keefe Chen
 */

import { Router } from "express";

import {
  createRoadmap,
  getRoadmaps,
  getRoadmapById,
  updateRoadmap,
  deleteRoadmap,
  addMilestone,
  updateMilestone,
} from "../controllers/roadmap.controller";

import { requireAuth } from "../middleware/auth.js";

const router = Router();

// All roadmap endpoints require authentication.
router.use(requireAuth);

/*
|--------------------------------------------------------------------------
| Roadmap Management
|--------------------------------------------------------------------------
*/

// POST /api/v1/roadmaps
// Create a new roadmap.
router.post("/", createRoadmap);

// GET /api/v1/roadmaps
// Retrieve all roadmaps accessible to the authenticated user.
router.get("/", getRoadmaps);

// GET /api/v1/roadmaps/:roadmapId
// Retrieve a specific roadmap.
router.get("/:roadmapId", getRoadmapById);

// PATCH /api/v1/roadmaps/:roadmapId
// Update an existing roadmap.
router.patch("/:roadmapId", updateRoadmap);

// DELETE /api/v1/roadmaps/:roadmapId
// Delete a roadmap.
router.delete("/:roadmapId", deleteRoadmap);

/*
|--------------------------------------------------------------------------
| Milestone Management
|--------------------------------------------------------------------------
*/

// POST /api/v1/roadmaps/:roadmapId/milestones
// Add a milestone to a roadmap.
router.post("/:roadmapId/milestones", addMilestone);

// PATCH /api/v1/roadmaps/:roadmapId/milestones/:milestoneId
// Update an existing milestone.
router.patch(
  "/:roadmapId/milestones/:milestoneId",
  updateMilestone
);

export default router;
