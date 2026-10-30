/**
 * File Name: task.controller.ts
 * Description: Handles HTTP requests and responses for task management.
 * Author: Keefe Chen
 */

import { Request, Response, NextFunction } from "express";
import * as taskService from "../services/task.service.js";
import { requireUserId } from "../middleware/auth.js";

/**
 * Create a new task.
 * POST /api/tasks
 */
export const createTask = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = requireUserId(req);

    const task = await taskService.createTask({
      ...req.body,
      createdBy: userId,
    });

    res.status(201).json({
      success: true,
      message: "Task created successfully.",
      data: task,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Retrieve all tasks belonging to the authenticated user.
 * GET /api/tasks
 */
export const getTasks = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = requireUserId(req);

    // Safely parse query parameters to single string values
    const filters = {
      status: typeof req.query.status === "string" ? req.query.status : undefined,
      priority: typeof req.query.priority === "string" ? req.query.priority : undefined,
      groupId: typeof req.query.groupId === "string" ? req.query.groupId : undefined,
    };

    const tasks = await taskService.getTasks(userId, filters);

    res.status(200).json({
      success: true,
      message: "Tasks retrieved successfully.",
      data: tasks,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Retrieve a specific task by its ID.
 * GET /api/tasks/:taskId
 */
export const getTaskById = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = requireUserId(req);
    const taskId = req.params.taskId as string;

    const task = await taskService.getTaskById(taskId, userId);

    res.status(200).json({
      success: true,
      message: "Task retrieved successfully.",
      data: task,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update an existing task.
 * PATCH /api/tasks/:taskId
 */
export const updateTask = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = requireUserId(req);
    const taskId = req.params.taskId as string;

    const task = await taskService.updateTask(taskId, userId, req.body);

    res.status(200).json({
      success: true,
      message: "Task updated successfully.",
      data: task,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete an existing task.
 * DELETE /api/tasks/:taskId
 */
export const deleteTask = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = requireUserId(req);
    const taskId = req.params.taskId as string;

    await taskService.deleteTask(taskId, userId);

    res.status(200).json({
      success: true,
      message: "Task deleted successfully.",
    });
  } catch (error) {
    next(error);
  }
};