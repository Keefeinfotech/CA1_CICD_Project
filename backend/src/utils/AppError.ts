
/**
 * File Name: AppError.ts
 * Description: Defines reusable application errors and HTTP status codes.
 * Author: Keefe Chen
 */

export class AppError extends Error {
  readonly status: number;
  readonly code: string;
  readonly details?: unknown;

  constructor(
    status: number,
    code: string,
    message: string,
    details?: unknown
  ) {
    super(message);

    this.name = "AppError";
    this.status = status;
    this.code = code;
    this.details = details;

    // Maintain the correct prototype chain.
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

// HTTP 400 - Bad Request.
export const badRequest = (
  message: string,
  details?: unknown
): AppError =>
  new AppError(400, "BAD_REQUEST", message, details);

// HTTP 401 - Unauthorized.
export const unauthorized = (
  message = "Authentication required"
): AppError =>
  new AppError(401, "UNAUTHORIZED", message);

// HTTP 403 - Forbidden.
export const forbidden = (
  message = "You do not have permission to perform this action."
): AppError =>
  new AppError(403, "FORBIDDEN", message);

// HTTP 404 - Not Found.
export const notFound = (
  message = "Resource not found"
): AppError =>
  new AppError(404, "NOT_FOUND", message);

// HTTP 409 - Conflict.
export const conflict = (
  message: string
): AppError =>
  new AppError(409, "CONFLICT", message);
