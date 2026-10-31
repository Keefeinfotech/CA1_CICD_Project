import type { UserRole } from "../constants/security.js";

declare global {
  namespace Express {
    interface Request {
      userId?: string;
      userEmail?: string;
      userRole?: UserRole;
      requestId: string;
    }
  }
}

export {};
