
/**
 * File Name: roadmap.controller.ts
 * Description: Handles HTTP requests for roadmap and milestone
 *              management, delegating business operations to the service layer.
 * Author: Keefe Chen
 */

import type { NextFunction, Request, Response } from "express";

import * as roadmapService from "../services/roadmap.service.js";
import { requireUserId } from "../middleware/auth.js";
import { badRequest } from "../utils/AppError.js";

// -----------------------------------------------------------------------------
// Shared Response Helper
// -----------------------------------------------------------------------------

/**
 * Sends a consistent successful API response.
 *
 * @param res - Express response object.
 * @param statusCode - HTTP status code.
 * @param message - Response message.
 * @param data - Optional response data.
 */
const sendSuccess = (
  res: Response,
  statusCode: number,
  message: string,
  data?: unknown
): void => {
  res.status(statusCode).json({
    success: true,
    message,
    ...(data !== undefined && { data }),
  });
};

// -----------------------------------------------------------------------------
// Route Parameter Validation
// -----------------------------------------------------------------------------

/**
 * Extracts and validates a single route parameter.
 *
 * Express route parameters may be typed as string | string[].
 * This helper ensures that the returned value is always a valid string.
 *
 * @param value - Route parameter.
 * @param paramName - Name of the parameter.
 * @returns Validated route parameter.
 */
const requireRouteParam = (
  value: string | string[] | undefined,
  paramName: string
): string => {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw badRequest(`Invalid or missing parameter: ${paramName}`);
  }

  return value.trim();
};

// -----------------------------------------------------------------------------
// Roadmap Management
// -----------------------------------------------------------------------------

/**
 * Create a roadmap.
 * POST /api/v1/roadmaps
 */
export const createRoadmap = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = requireUserId(req);

    const roadmap = await roadmapService.createRoadmap(
      req.body,
      userId
    );

    sendSuccess(
      res,
      201,
      "Roadmap created successfully.",
      roadmap
    );
  } catch (error) {
    next(error);
  }
};

/**
 * Retrieve roadmaps belonging to the authenticated user.
 * GET /api/v1/roadmaps
 */
export const getRoadmaps = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = requireUserId(req);

    const result = await roadmapService.getRoadmaps(
      userId,
      req.query
    );

    sendSuccess(
      res,
      200,
      "Roadmaps retrieved successfully.",
      result
    );
  } catch (error) {
    next(error);
  }
};

/**
 * Retrieve a specific roadmap.
 * GET /api/v1/roadmaps/:roadmapId
 */
export const getRoadmapById = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = requireUserId(req);

    const roadmapId = requireRouteParam(
      req.params.roadmapId,
      "roadmapId"
    );

    const roadmap = await roadmapService.getRoadmapById(
      roadmapId,
      userId
    );

    sendSuccess(
      res,
      200,
      "Roadmap retrieved successfully.",
      roadmap
    );
  } catch (error) {
    next(error);
  }
};

/**
 * Update a roadmap.
 * PATCH /api/v1/roadmaps/:roadmapId
 */
export const updateRoadmap = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = requireUserId(req);

    const roadmapId = requireRouteParam(
      req.params.roadmapId,
      "roadmapId"
    );

    const roadmap = await roadmapService.updateRoadmap(
      roadmapId,
      userId,
      req.body
    );

    sendSuccess(
      res,
      200,
      "Roadmap updated successfully.",
      roadmap
    );
  } catch (error) {
    next(error);
  }
};

/**
 * Delete a roadmap.
 * DELETE /api/v1/roadmaps/:roadmapId
 */
export const deleteRoadmap = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = requireUserId(req);

    const roadmapId = requireRouteParam(
      req.params.roadmapId,
      "roadmapId"
    );

    await roadmapService.deleteRoadmap(
      roadmapId,
      userId
    );

    sendSuccess(
      res,
      200,
      "Roadmap deleted successfully."
    );
  } catch (error) {
    next(error);
  }
};

// -----------------------------------------------------------------------------
// Milestone Management
// -----------------------------------------------------------------------------

/**
 * Add a milestone to a roadmap.
 * POST /api/v1/roadmaps/:roadmapId/milestones
 */
export const addMilestone = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = requireUserId(req);

    const roadmapId = requireRouteParam(
      req.params.roadmapId,
      "roadmapId"
    );

    const milestone = await roadmapService.addMilestone(
      roadmapId,
      userId,
      req.body
    );

    sendSuccess(
      res,
      201,
      "Milestone added successfully.",
      milestone
    );
  } catch (error) {
    next(error);
  }
};

/**
 * Update an existing milestone.
 * PATCH /api/v1/roadmaps/:roadmapId/milestones/:milestoneId
 */
export const updateMilestone = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = requireUserId(req);

    const roadmapId = requireRouteParam(
      req.params.roadmapId,
      "roadmapId"
    );

    const milestoneId = requireRouteParam(
      req.params.milestoneId,
      "milestoneId"
    );

    const milestone = await roadmapService.updateMilestone(
      roadmapId,
      milestoneId,
      userId,
      req.body
    );

    sendSuccess(
      res,
      200,
      "Milestone updated successfully.",
      milestone
    );
  } catch (error) {
    next(error);
  }
};
