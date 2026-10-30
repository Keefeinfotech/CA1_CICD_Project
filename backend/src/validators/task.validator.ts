import { Request, Response, NextFunction } from "express";
import { z } from "zod";

const taskIdSchema = z.object({
  taskId: z.string().uuid(),
});

const createTaskSchema = z.object({
  title: z.string().trim().min(1).max(150),
  description: z.string().max(2000).optional(),
  dueDate: z.coerce.date().optional(),
});

const updateTaskSchema = z.object({
  title: z.string().trim().min(1).max(150).optional(),
  description: z.string().max(2000).nullable().optional(),
  dueDate: z.coerce.date().nullable().optional(),
});

const getTasksSchema = z.object({
  status: z.enum(["TODO", "IN_PROGRESS", "COMPLETED"]).optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const validateTaskId = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const result = taskIdSchema.safeParse(req.params);

  if (!result.success) {
    res.status(400).json({
      success: false,
      message: "Invalid task ID.",
      errors: result.error.flatten(),
    });
    return;
  }

  next();
};

export const validateCreateTask = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const result = createTaskSchema.safeParse(req.body);

  if (!result.success) {
    res.status(400).json({
      success: false,
      message: "Invalid task data.",
      errors: result.error.flatten(),
    });
    return;
  }

  req.body = result.data;
  next();
};

export const validateUpdateTask = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const result = updateTaskSchema.safeParse(req.body);

  if (!result.success || Object.keys(result.data ?? {}).length === 0) {
    res.status(400).json({
      success: false,
      message: "Invalid or empty task update.",
      errors: result.success ? undefined : result.error.flatten(),
    });
    return;
  }

  req.body = result.data;
  next();
};

export const validateGetTasks = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const result = getTasksSchema.safeParse(req.query);

  if (!result.success) {
    res.status(400).json({
      success: false,
      message: "Invalid query parameters.",
      errors: result.error.flatten(),
    });
    return;
  }

  req.query = result.data as unknown as typeof req.query;
  next();
};