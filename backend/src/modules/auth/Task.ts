
/**
 * File Name: Task.ts
 * Description: Defines the database schema and types for individual and group tasks.
 * Author: Keefe Chen
 */

import mongoose, { Document, Schema, Types } from "mongoose";

// Available task statuses.
export type TaskStatus = "TODO" | "IN_PROGRESS" | "COMPLETED";

// Available task priorities.
export type TaskPriority = "LOW" | "MEDIUM" | "HIGH";

// Task document interface.
export interface ITask extends Document {
  _id: Types.ObjectId;
  taskId?: string; // Transformed identifier for API responses.

  title: string;
  description?: string;

  // Task ownership.
  createdBy: Types.ObjectId;
  assignedTo?: Types.ObjectId | null;
  groupId?: Types.ObjectId | null;

  // Task details.
  status: TaskStatus;
  priority: TaskPriority;
  dueDate?: Date | null;

  createdAt: Date;
  updatedAt: Date;
}

// Task schema definition.
const taskSchema = new Schema<ITask>(
  {
    title: {
      type: String,
      required: [true, "Task title is required."],
      trim: true,
      minlength: 1,
      maxlength: 150,
    },

    description: {
      type: String,
      trim: true,
      maxlength: 2000,
    },

    // User who created the task.
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    // User assigned to the task.
    assignedTo: {
      type: Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    // Group associated with the task.
    groupId: {
      type: Schema.Types.ObjectId,
      ref: "Group",
      default: null,
      index: true,
    },

    status: {
      type: String,
      enum: ["TODO", "IN_PROGRESS", "COMPLETED"],
      default: "TODO",
      index: true,
    },

    priority: {
      type: String,
      enum: ["LOW", "MEDIUM", "HIGH"],
      default: "MEDIUM",
    },

    dueDate: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// Map _id to taskId in JSON outputs.
// Keep the original MongoDB _id in the database document.
taskSchema.set("toJSON", {
  virtuals: true,
  transform: (_doc, ret) => {
    const { _id, __v, ...taskData } = ret;

    return {
      ...taskData,
      taskId: String(_id),
    };
  },
});

// Compound indexes for common task queries.
taskSchema.index({ createdBy: 1, status: 1, createdAt: -1 });
taskSchema.index({ groupId: 1, status: 1, dueDate: 1 });
taskSchema.index({ assignedTo: 1, status: 1 });

export const Task = mongoose.model<ITask>("Task", taskSchema);
