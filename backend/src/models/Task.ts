import mongoose, { Document, Schema } from "mongoose";

export type ITask = Document & {
  title: string;
  description?: string;
  createdBy: Schema.Types.ObjectId;
  assignedTo?: Schema.Types.ObjectId | null;
  groupId?: Schema.Types.ObjectId | null;
  status: "TODO" | "IN_PROGRESS" | "COMPLETED";
  priority: "LOW" | "MEDIUM" | "HIGH";
  dueDate?: Date | null;
  createdAt: Date;
  updatedAt: Date;
};

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
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    assignedTo: {
      type: Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },
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

taskSchema.index({ createdBy: 1, status: 1, createdAt: -1 });
taskSchema.index({ groupId: 1, status: 1, dueDate: 1 });
taskSchema.index({ assignedTo: 1, status: 1 });

export const Task = mongoose.model<ITask>("Task", taskSchema);