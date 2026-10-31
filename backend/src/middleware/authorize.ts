import type { NextFunction, Request, RequestHandler, Response } from "express";
import type { UserRole } from "../constants/security.js";
import { forbidden, unauthorized } from "../utils/AppError.js";
import { logSecurityEvent } from "../utils/securityLogger.js";

export const authorize = (...allowedRoles: UserRole[]): RequestHandler => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.userRole) {
      throw unauthorized();
    }

    if (allowedRoles.length > 0 && !allowedRoles.includes(req.userRole)) {
      logSecurityEvent("authorization_denied", {
        requestId: req.requestId,
        userId: req.userId,
        role: req.userRole,
        path: req.path,
      });
      throw forbidden();
    }

    next();
  };
};
