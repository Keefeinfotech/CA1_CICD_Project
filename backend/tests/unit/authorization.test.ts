import type { NextFunction, Request, Response } from "express";
import { afterEach, describe, expect, it, vi } from "vitest";
import { authorize } from "../../src/middleware/authorize";
import { AppError } from "../../src/utils/AppError";
import { requireUserId } from "../../src/utils/request";

const mockRequest = (overrides: Partial<Request> = {}): Request =>
  ({ requestId: "req-1", ...overrides }) as Request;

afterEach(() => {
  vi.restoreAllMocks();
});

describe("authorize", () => {
  it("rejects an unauthenticated request", () => {
    expect(() => authorize("admin")(
      mockRequest(),
      {} as Response,
      vi.fn() as NextFunction
    )).toThrow(
      expect.objectContaining({ status: 401, code: "UNAUTHORIZED" })
    );
  });

  it("rejects a role that is not allowed", () => {
    vi.spyOn(console, "warn").mockImplementation(() => undefined);
    const next = vi.fn();

    expect(() =>
      authorize("admin")(
        mockRequest({ userId: "user-1", userRole: "user" }),
        {} as Response,
        next as NextFunction
      )
    ).toThrow(expect.objectContaining({ status: 403, code: "FORBIDDEN" }));
    expect(next).not.toHaveBeenCalled();
  });

  it("allows an explicitly permitted role", () => {
    const next = vi.fn();
    authorize("admin")(
      mockRequest({ userId: "user-1", userRole: "admin" }),
      {} as Response,
      next as NextFunction
    );
    expect(next).toHaveBeenCalledTimes(1);
  });

  it("allows any authenticated role when no roles are listed", () => {
    const next = vi.fn();
    authorize()(
      mockRequest({ userId: "user-1", userRole: "user" }),
      {} as Response,
      next as NextFunction
    );
    expect(next).toHaveBeenCalledTimes(1);
  });
});

describe("requireUserId", () => {
  it("returns the authenticated user id", () => {
    expect(requireUserId(mockRequest({ userId: "user-1" }))).toBe("user-1");
  });

  it("throws when authentication middleware did not run", () => {
    expect(() => requireUserId(mockRequest())).toThrow(AppError);
  });
});
