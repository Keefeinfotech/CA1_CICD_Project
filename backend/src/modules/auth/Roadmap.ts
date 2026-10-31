
import mongoose, {
  Schema,
  Types,
  type HydratedDocument,
  type HydratedArraySubdocument,
} from "mongoose";

export type RoadmapStatus =
  | "PLANNED"
  | "ACTIVE"
  | "COMPLETED"
  | "ON_HOLD";

export type RoadmapPriority = "LOW" | "MEDIUM" | "HIGH";

export type MilestoneStatus =
  | "TODO"
  | "IN_PROGRESS"
  | "COMPLETED";

// -----------------------------------------------------------------------------
// Milestone Types
// -----------------------------------------------------------------------------

export interface IMilestone {
  title: string;
  description?: string;
  status: MilestoneStatus;
  assignedTo?: Types.ObjectId | null;
  dueDate?: Date | null;
  completedAt?: Date | null;
  order: number;
}

export type MilestoneDocument = HydratedArraySubdocument<IMilestone>;

export type CreateMilestoneInput = IMilestone;

// -----------------------------------------------------------------------------
// Roadmap Types
// -----------------------------------------------------------------------------

export interface IRoadmap {
  title: string;
  description?: string;
  createdBy: Types.ObjectId;
  status: RoadmapStatus;
  priority: RoadmapPriority;
  startDate?: Date | null;
  dueDate?: Date | null;
}

export type RoadmapDocument = HydratedDocument<
  IRoadmap,
  {
    milestones: Types.DocumentArray<IMilestone>;
  }
>;

// -----------------------------------------------------------------------------
// Milestone Schema
// -----------------------------------------------------------------------------

const milestoneSchema = new Schema<IMilestone>(
  {
    title: {
      type: String,
      required: true,
      trim: true,
      minlength: 1,
      maxlength: 150,
    },
    description: {
      type: String,
      trim: true,
      maxlength: 2000,
    },
    status: {
      type: String,
      enum: ["TODO", "IN_PROGRESS", "COMPLETED"],
      default: "TODO",
    },
    assignedTo: {
      type: Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },
    dueDate: {
      type: Date,
      default: null,
    },
    completedAt: {
      type: Date,
      default: null,
    },
    order: {
      type: Number,
      default: 0,
      min: 0,
    },
  },
  { timestamps: true }
);

// -----------------------------------------------------------------------------
// Roadmap Schema
// -----------------------------------------------------------------------------

const roadmapSchema = new Schema<IRoadmap>(
  {
    title: {
      type: String,
      required: true,
      trim: true,
      minlength: 1,
      maxlength: 150,
    },
    description: {
      type: String,
      trim: true,
      maxlength: 3000,
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: ["PLANNED", "ACTIVE", "COMPLETED", "ON_HOLD"],
      default: "PLANNED",
      index: true,
    },
    priority: {
      type: String,
      enum: ["LOW", "MEDIUM", "HIGH"],
      default: "MEDIUM",
    },
    startDate: {
      type: Date,
      default: null,
    },
    dueDate: {
      type: Date,
      default: null,
    },
    milestones: {
      type: [milestoneSchema],
      default: [],
    },
  },
  {
    timestamps: true,
    versionKey: false,
  }
);

// -----------------------------------------------------------------------------
// Database Indexes
// -----------------------------------------------------------------------------

roadmapSchema.index({
  createdBy: 1,
  status: 1,
  updatedAt: -1,
});

roadmapSchema.index({
  createdBy: 1,
  dueDate: 1,
});

// -----------------------------------------------------------------------------
// JSON Transformation
// -----------------------------------------------------------------------------

roadmapSchema.set("toJSON", {
  virtuals: true,
  transform: (_doc, ret) => {
    const { _id, __v, ...roadmapData } = ret;

    return {
      ...roadmapData,
      roadmapId: String(_id),
    };
  },
});

// -----------------------------------------------------------------------------
// Model Export
// -----------------------------------------------------------------------------

export const Roadmap = mongoose.model<IRoadmap>("Roadmap", roadmapSchema);
