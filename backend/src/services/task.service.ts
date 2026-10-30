/**
 * File Name: task.service.ts
 * Description: Handles business logic for task management.
 * Author: Keefe Chen
 */

import { Task, ITask } from "../models/Task.js";

/**
 * Create a new task for the authenticated user.
 */
export const createTask = async (taskData: Partial<ITask>): Promise<ITask> => {
  const task = await Task.create(taskData);
  return task;
};

/**
 * Retrieve all tasks belonging to a user (as creator or assignee).
 * Supports filtering by status, priority, or groupId.
 */
export const getTasks = async (
  userId: string,
  filters: { status?: string; priority?: string; groupId?: string } = {}
): Promise<ITask[]> => {
  const query: Record<string, any> = {
    $or: [{ createdBy: userId }, { assignedTo: userId }],
  };

  // Filter tasks by status if provided.
  if (filters.status) {
    query.status = filters.status;
  }

  // Filter tasks by priority if provided.
  if (filters.priority) {
    query.priority = filters.priority;
  }

  // Filter tasks by group if provided.
  if (filters.groupId) {
    query.groupId = filters.groupId;
  }

  const tasks = await Task.find(query).sort({ createdAt: -1 });
  return tasks;
};

/**
 * Retrieve a specific task by its taskId (_id) belonging to a user.
 */
export const getTaskById = async (
  taskId: string,
  userId: string
): Promise<ITask> => {
  const task = await Task.findOne({
    _id: taskId,
    $or: [{ createdBy: userId }, { assignedTo: userId }],
  });

  if (!task) {
    throw Object.assign(new Error("Task not found."), {
      statusCode: 404,
      code: "NOT_FOUND",
    });
  }

  return task;
};

/**
 * Update an existing task by taskId (_id).
 */
export const updateTask = async (
  taskId: string,
  userId: string,
  updateData: Partial<ITask>
): Promise<ITask> => {
  const task = await Task.findOneAndUpdate(
    {
      _id: taskId,
      $or: [{ createdBy: userId }, { assignedTo: userId }],
    },
    {
      $set: updateData,
    },
    {
      new: true,
      runValidators: true,
    }
  );

  if (!task) {
    throw Object.assign(new Error("Task not found."), {
      statusCode: 404,
      code: "NOT_FOUND",
    });
  }

  return task;
};

/**
 * Delete an existing task by taskId (_id).
 */
export const deleteTask = async (
  taskId: string,
  userId: string
): Promise<ITask> => {
  const task = await Task.findOneAndDelete({
    _id: taskId,
    createdBy: userId, // Only creator can delete
  });

  if (!task) {
    throw Object.assign(new Error("Task not found or unauthorized to delete."), {
      statusCode: 404,
      code: "NOT_FOUND",
    });
  }

  return task;
};