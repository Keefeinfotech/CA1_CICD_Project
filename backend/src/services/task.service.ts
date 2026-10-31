
/**
 * File Name: task.service.ts
 * Description: Handles business logic for task management.
 * Author: Keefe Chen
 */

import mongoose, { Types } from "mongoose";
import { Task, ITask } from "../models/Task.js";

/**
 * Task status values supported by the Task model.
 */
type TaskStatus = "TODO" | "IN_PROGRESS" | "COMPLETED";

/**
 * Task priority values supported by the Task model.
 */
type TaskPriority = "LOW" | "MEDIUM" | "HIGH";

/**
 * Filters that can be applied when retrieving tasks.
 */
interface TaskFilters {
  status?: TaskStatus;
  priority?: TaskPriority;
  groupId?: string;
}

/**
 * Fields accepted when creating a task.
 *
 * createdBy is supplied by the authenticated user,
 * not directly trusted from the request body.
 */
type CreateTaskInput = {
  title: string;
  description?: string;
  assignedTo?: string | null;
  groupId?: string | null;
  status?: TaskStatus;
  priority?: TaskPriority;
  dueDate?: Date | null;
};

/**
 * Fields that can be updated on an existing task.
 *
 * createdBy, createdAt and updatedAt cannot be changed
 * through this update operation.
 */
type UpdateTaskInput = Partial<{
  title: string;
  description: string;
  assignedTo: string | null;
  groupId: string | null;
  status: TaskStatus;
  priority: TaskPriority;
  dueDate: Date | null;
}>;

/**
 * Creates a consistent service error.
 */
const createError = (message: string, statusCode: number) => {
  return Object.assign(new Error(message), { statusCode });
};

/**
 * Validates whether a supplied ID is a valid MongoDB ObjectId.
 */
const validateObjectId = (id: string, fieldName = "ID"): void => {
  if (!Types.ObjectId.isValid(id)) {
    throw createError(`Invalid ${fieldName}.`, 400);
  }
};

/**
 * Creates a new task.
 */
export const createTask = async (
  taskData: CreateTaskInput,
  userId: string
) => {
  validateObjectId(userId, "user ID");

  if (taskData.assignedTo) {
    validateObjectId(taskData.assignedTo, "assigned user ID");
  }

  if (taskData.groupId) {
    validateObjectId(taskData.groupId, "group ID");
  }

  const task = await Task.create({
    title: taskData.title,
    description: taskData.description,
    createdBy: userId,
    assignedTo: taskData.assignedTo || null,
    groupId: taskData.groupId || null,
    status: taskData.status ?? "TODO",
    priority: taskData.priority ?? "MEDIUM",
    dueDate: taskData.dueDate ?? null,
  });

  return task;
};

/**
 * Retrieves tasks created by or assigned to the user.
 */
export const getTasks = async (
  userId: string,
  filters: TaskFilters = {}
) => {
  validateObjectId(userId, "user ID");

  const query: mongoose.FilterQuery<ITask> = {
    $or: [
      { createdBy: new Types.ObjectId(userId) },
      { assignedTo: new Types.ObjectId(userId) },
    ],
  };

  if (filters.status) {
    query.status = filters.status;
  }

  if (filters.priority) {
    query.priority = filters.priority;
  }

  if (filters.groupId) {
    validateObjectId(filters.groupId, "group ID");
    query.groupId = new Types.ObjectId(filters.groupId);
  }

  return Task.find(query).sort({ createdAt: -1 });
};

/**
 * Retrieves a task by ID if the user created it
 * or is assigned to it.
 */
export const getTaskById = async (
  taskId: string,
  userId: string
) => {
  validateObjectId(taskId, "task ID");
  validateObjectId(userId, "user ID");

  const task = await Task.findOne({
    _id: new Types.ObjectId(taskId),
    $or: [
      { createdBy: new Types.ObjectId(userId) },
      { assignedTo: new Types.ObjectId(userId) },
    ],
  });

  if (!task) {
    throw createError("Task not found or access denied.", 404);
  }

  return task;
};

/**
 * Updates a task if the user created it or is assigned to it.
 */
export const updateTask = async (
  taskId: string,
  userId: string,
  updateData: UpdateTaskInput
) => {
  validateObjectId(taskId, "task ID");
  validateObjectId(userId, "user ID");

  // Validate optional ObjectId fields before updating.
  if (updateData.assignedTo) {
    validateObjectId(updateData.assignedTo, "assigned user ID");
  }

  if (updateData.groupId) {
    validateObjectId(updateData.groupId, "group ID");
  }

  const task = await Task.findOneAndUpdate(
    {
      _id: new Types.ObjectId(taskId),
      $or: [
        { createdBy: new Types.ObjectId(userId) },
        { assignedTo: new Types.ObjectId(userId) },
      ],
    },
    { $set: updateData },
    {
      new: true,
      runValidators: true,
    }
  );

  if (!task) {
    throw createError("Task not found or access denied.", 404);
  }

  return task;
};

/**
 * Deletes a task.
 *
 * Only the original creator is allowed to delete it.
 */
export const deleteTask = async (
  taskId: string,
  userId: string
) => {
  validateObjectId(taskId, "task ID");
  validateObjectId(userId, "user ID");

  const task = await Task.findOneAndDelete({
    _id: new Types.ObjectId(taskId),
    createdBy: new Types.ObjectId(userId),
  });

  if (!task) {
    throw createError("Task not found or deletion not permitted.", 404);
  }

  return task;
};
