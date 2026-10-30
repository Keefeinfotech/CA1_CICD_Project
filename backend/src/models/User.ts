import mongoose, { Document, Schema } from "mongoose";

export interface IUser extends Document {
  name?: string;
  email: string;
  passwordHash: string;
  lastLoginAt?: Date | null;
  // Single-session control: the jti of the newest login is stored here.
  // A token whose jti no longer matches is treated as replaced (logged out).
  activeSessionId?: string | null;
  activeSessionExpiresAt?: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema = new Schema<IUser>(
  {
    name: { type: String, trim: true, maxlength: 80 },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      maxlength: 254,
    },
    passwordHash: { type: String, required: true, select: false },
    lastLoginAt: { type: Date, default: null },
    activeSessionId: { type: String, default: null },
    activeSessionExpiresAt: { type: Date, default: null },
  },
  { timestamps: true }
);

export const User = mongoose.model<IUser>("User", UserSchema);
