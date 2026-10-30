
/**
 * File Name: express.d.ts
 * Description: Extends Express Request with custom authentication properties.
 * Author: Keefe Chen
 */

declare global {
  namespace Express {
    interface Request {
      userId?: string;
      userEmail?: string;
      user?: {
        id: string;
        email: string;
        role?: string;
      };
      userRole: string;
    }
  }
}

export {};
