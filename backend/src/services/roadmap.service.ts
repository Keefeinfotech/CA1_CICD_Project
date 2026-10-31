
/**
 * File Name: roadmap.service.ts
 * Description: Implements business logic for roadmap and milestone
 *              creation, retrieval, updating and deletion.
 * Author: Keefe Chen
 */

import mongoose, { Types } from "mongoose";

import {
  Roadmap,
  RoadmapStatus,
  RoadmapPriority,
  MilestoneStatus,
} from "../models/Roadmap.js";

import {
  badRequest,
  notFound,
} from "../utils/AppError.js";

// -----------------------------------------------------------------------------
// Input Types
// -----------------------------------------------------------------------------

interface CreateRoadmapInput {
  title: string;
  description?: string;
  status?: RoadmapStatus;
  priority?: RoadmapPriority;
  startDate?: string | Date | null;
  dueDate?: string | Date | null;
}

interface UpdateRoadmapInput {
  title?: string;
  description?: string;
  status?: RoadmapStatus;
  priority?: RoadmapPriority;
  startDate?: string | Date | null;
  dueDate?: string | Date | null;
}

interface CreateMilestoneInput {
  title: string;
  description?: string;
  status?: MilestoneStatus;
  assignedTo?: string | null;
  dueDate?: string | Date | null;
  order?: number;
}

interface UpdateMilestoneInput {
  title?: string;
  description?: string;
  status?: MilestoneStatus;
  assignedTo?: string | null;
  dueDate?: string | Date | null;
  order?: number;
}

// -----------------------------------------------------------------------------
// Shared Validation Helpers
// -----------------------------------------------------------------------------

/**
 * Validate a MongoDB ObjectId.
 */
const validateObjectId = (
  id: string,
  fieldName: string
): Types.ObjectId => {
  if (!/^[a-f\d]{24}$/i.test(id)) {
    throw badRequest(`Invalid ${fieldName}.`);
  }

  return new Types.ObjectId(id);
};

/**
 * Convert an optional date value into a valid Date.
 */
const parseOptionalDate = (
  value: string | Date | null | undefined,
  fieldName: string
): Date | null | undefined => {
  if (value === undefined) {
    return undefined;
  }

  if (value === null || value === "") {
    return null;
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    throw badRequest(`Invalid ${fieldName}.`);
  }

  return date;
};

/**
 * Validate that a roadmap target date is not earlier
 * than its start date.
 */
const validateRoadmapDates = (
  startDate: Date | null | undefined,
  dueDate: Date | null | undefined
): void => {
  if (startDate && dueDate && dueDate < startDate) {
    throw badRequest(
      "Roadmap due date cannot be earlier than its start date."
    );
  }
};

/**
 * Find a roadmap owned by the authenticated user.
 *
 * Returning 404 for inaccessible roadmaps avoids revealing
 * whether another user's roadmap exists.
 */
const findOwnedRoadmap = async (
  roadmapId: string,
  userId: string
) => {
  const roadmapObjectId = validateObjectId(
    roadmapId,
    "roadmap ID"
  );

  const userObjectId = validateObjectId(
    userId,
    "user ID"
  );

  const roadmap = await Roadmap.findOne({
    _id: roadmapObjectId,
    createdBy: userObjectId,
  });

  if (!roadmap) {
    throw notFound("Roadmap not found.");
  }

  return roadmap;
};

// -----------------------------------------------------------------------------
// Roadmap Management
// -----------------------------------------------------------------------------

/**
 * Create a roadmap.
 */
export const createRoadmap = async (
  input: CreateRoadmapInput,
  userId: string
) => {
  const ownerId = validateObjectId(userId, "user ID");

  const title = input.title?.trim();

  if (!title) {
    throw badRequest("Roadmap title is required.");
  }

  const startDate = parseOptionalDate(
    input.startDate,
    "start date"
  );

  const dueDate = parseOptionalDate(
    input.dueDate,
    "due date"
  );

  validateRoadmapDates(startDate, dueDate);

  const roadmap = await Roadmap.create({
    title,
    description: input.description?.trim(),
    status: input.status ?? "PLANNED",
    priority: input.priority ?? "MEDIUM",
    startDate,
    dueDate,
    createdBy: ownerId,
    milestones: [],
  });

  return roadmap;
};

/**
 * Retrieve roadmaps with filtering and pagination.
 */
export const getRoadmaps = async (
  userId: string,
  query: unknown = {}
) => {
  const ownerId = validateObjectId(userId, "user ID");

  const filters =
    typeof query === "object" && query !== null
      ? query as Record<string, unknown>
      : {};

  const page = Number(filters.page ?? 1);
  const limit = Number(filters.limit ?? 10);

  if (
    !Number.isInteger(page) ||
    !Number.isInteger(limit) ||
    page < 1 ||
    limit < 1 ||
    limit > 100
  ) {
    throw badRequest(
      "Invalid pagination parameters. Page must be at least 1 and limit must be between 1 and 100."
    );
  }

  const filter: Record<string, unknown> = {
    createdBy: ownerId,
  };

  if (filters.status !== undefined) {
    const allowedStatuses: RoadmapStatus[] = [
      "PLANNED",
      "ACTIVE",
      "COMPLETED",
      "ON_HOLD",
    ];

    if (
      typeof filters.status !== "string" ||
      !allowedStatuses.includes(filters.status as RoadmapStatus)
    ) {
      throw badRequest("Invalid roadmap status filter.");
    }

    filter.status = filters.status;
  }

  if (filters.priority !== undefined) {
    const allowedPriorities: RoadmapPriority[] = [
      "LOW",
      "MEDIUM",
      "HIGH",
    ];

    if (
      typeof filters.priority !== "string" ||
      !allowedPriorities.includes(filters.priority as RoadmapPriority)
    ) {
      throw badRequest("Invalid roadmap priority filter.");
    }

    filter.priority = filters.priority;
  }

  const skip = (page - 1) * limit;

  const [roadmaps, total] = await Promise.all([
    Roadmap.find(filter)
      .sort({ updatedAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),

    Roadmap.countDocuments(filter),
  ]);

  return {
    items: roadmaps,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
      hasNextPage: page * limit < total,
      hasPreviousPage: page > 1,
    },
  };
};

/**
 * Retrieve a specific roadmap.
 */
export const getRoadmapById = async (
  roadmapId: string,
  userId: string
) => {
  return findOwnedRoadmap(roadmapId, userId);
};

/**
 * Update a roadmap.
 */
export const updateRoadmap = async (
  roadmapId: string,
  userId: string,
  input: UpdateRoadmapInput
) => {
  const roadmap = await findOwnedRoadmap(
    roadmapId,
    userId
  );

  // Only explicitly supported fields can be updated.
  if (input.title !== undefined) {
    const title = input.title.trim();

    if (!title) {
      throw badRequest("Roadmap title cannot be empty.");
    }

    roadmap.title = title;
  }

  if (input.description !== undefined) {
    roadmap.description = input.description.trim();
  }

  if (input.status !== undefined) {
    roadmap.status = input.status;
  }

  if (input.priority !== undefined) {
    roadmap.priority = input.priority;
  }

  if (input.startDate !== undefined) {
    roadmap.startDate = parseOptionalDate(
      input.startDate,
      "start date"
    ) ?? null;
  }

  if (input.dueDate !== undefined) {
    roadmap.dueDate = parseOptionalDate(
      input.dueDate,
      "due date"
    ) ?? null;
  }

  validateRoadmapDates(
    roadmap.startDate,
    roadmap.dueDate
  );

  await roadmap.save();

  return roadmap;
};

/**
 * Delete a roadmap.
 */
export const deleteRoadmap = async (
  roadmapId: string,
  userId: string
): Promise<void> => {
  const roadmap = await findOwnedRoadmap(
    roadmapId,
    userId
  );

  await roadmap.deleteOne();
};

// -----------------------------------------------------------------------------
// Milestone Management
// -----------------------------------------------------------------------------

/**
 * Add a milestone to a roadmap.
 */
export const addMilestone = async (
  roadmapId: string,
  userId: string,
  input: CreateMilestoneInput
) => {
  const roadmap = await findOwnedRoadmap(
    roadmapId,
    userId
  );

  const title = input.title?.trim();

  if (!title) {
    throw badRequest("Milestone title is required.");
  }

  const dueDate = parseOptionalDate(
    input.dueDate,
    "milestone due date"
  );

  if (
    dueDate &&
    roadmap.dueDate &&
    dueDate > roadmap.dueDate
  ) {
    throw badRequest(
      "Milestone due date cannot be later than the roadmap due date."
    );
  }

  let assignedTo: Types.ObjectId | null = null;

  if (input.assignedTo) {
    assignedTo = validateObjectId(
      input.assignedTo,
      "assigned user ID"
    );
  }

  const milestone = {
    title,
    description: input.description?.trim(),
    status: input.status ?? "TODO",
    assignedTo,
    dueDate: dueDate ?? null,
    completedAt:
      input.status === "COMPLETED" ? new Date() : null,
    order: input.order ?? roadmap.milestones.length,
  };

  roadmap.milestones.push(milestone);

  await roadmap.save();

  return roadmap.milestones[roadmap.milestones.length - 1];
};

/**
 * Update a milestone belonging to a roadmap.
 */
export const updateMilestone = async (
  roadmapId: string,
  milestoneId: string,
  userId: string,
  input: UpdateMilestoneInput
) => {
  const roadmap = await findOwnedRoadmap(
    roadmapId,
    userId
  );

  const milestoneObjectId = validateObjectId(
    milestoneId,
    "milestone ID"
  );

  const milestone = roadmap.milestones.find(
    (item) => item._id.equals(milestoneObjectId)
  );

  if (!milestone) {
    throw notFound("Milestone not found.");
  }

  if (input.title !== undefined) {
    const title = input.title.trim();

    if (!title) {
      throw badRequest("Milestone title cannot be empty.");
    }

    milestone.title = title;
  }

  if (input.description !== undefined) {
    milestone.description = input.description.trim();
  }

  if (input.status !== undefined) {
    milestone.status = input.status;

    milestone.completedAt =
      input.status === "COMPLETED"
        ? milestone.completedAt ?? new Date()
        : null;
  }

  if (input.assignedTo !== undefined) {
    milestone.assignedTo = input.assignedTo
      ? validateObjectId(
          input.assignedTo,
          "assigned user ID"
        )
      : null;
  }

  if (input.dueDate !== undefined) {
    milestone.dueDate =
      parseOptionalDate(
        input.dueDate,
        "milestone due date"
      ) ?? null;
  }

  if (input.order !== undefined) {
    if (
      !Number.isInteger(input.order) ||
      input.order < 0
    ) {
      throw badRequest(
        "Milestone order must be a non-negative integer."
      );
    }

    milestone.order = input.order;
  }

  if (
    milestone.dueDate &&
    roadmap.dueDate &&
    milestone.dueDate > roadmap.dueDate
  ) {
    throw badRequest(
      "Milestone due date cannot be later than the roadmap due date."
    );
  }

  await roadmap.save();

  return milestone;
};
