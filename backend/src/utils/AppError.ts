export class AppError extends Error {
  readonly status: number;
  readonly code: string;
  readonly details?: unknown;

  constructor(status: number, code: string, message: string, details?: unknown) {
    super(message);
    this.name = "AppError";
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export const unauthorized = (message = "Authentication required"): AppError =>
  new AppError(401, "UNAUTHORIZED", message);

export const forbidden = (message = "Insufficient permissions"): AppError =>
  new AppError(403, "FORBIDDEN", message);

export const conflict = (message: string): AppError =>
  new AppError(409, "CONFLICT", message);

export const sessionReplaced = (): AppError =>
  new AppError(
    401,
    "SESSION_REPLACED",
    "Session ended. This account signed in on another device."
  );
