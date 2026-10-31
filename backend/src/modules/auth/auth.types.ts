import type { UserRole } from "../../constants/security.js";

export interface PublicUser {
  id: string;
  name?: string;
  email: string;
}

export interface AuthenticatedUser extends PublicUser {
  role: UserRole;
}

export interface AuthResult {
  token: string;
  user: PublicUser;
}
