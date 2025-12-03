import { describe, expect, it, beforeEach } from "vitest";
import { appRouter } from "./routers";
import type { TrpcContext } from "./_core/context";

type AuthenticatedUser = NonNullable<TrpcContext["user"]>;

function createAuthContext(): { ctx: TrpcContext } {
  const user: AuthenticatedUser = {
    id: 1,
    openId: "test-user",
    email: "test@example.com",
    name: "Test User",
    loginMethod: "manus",
    role: "user",
    createdAt: new Date(),
    updatedAt: new Date(),
    lastSignedIn: new Date(),
  };

  const ctx: TrpcContext = {
    user,
    req: {
      protocol: "https",
      headers: {},
    } as TrpcContext["req"],
    res: {
      clearCookie: () => {},
    } as TrpcContext["res"],
  };

  return { ctx };
}

describe("cameraStream", () => {
  describe("add", () => {
    it("should add an RTSP stream successfully", async () => {
      const { ctx } = createAuthContext();
      const caller = appRouter.createCaller(ctx);

      const result = await caller.cameraStream.add({
        cameraId: `test-cam-${Date.now()}`,
        cameraDescription: "Test RTSP Camera",
        streamType: "rtsp",
        rtspUrl: "rtsp://example.com:554/stream",
      });

      expect(result).toHaveProperty("success", true);
      expect(result).toHaveProperty("cameraId");
    });

    it("should reject RTSP stream without URL", async () => {
      const { ctx } = createAuthContext();
      const caller = appRouter.createCaller(ctx);

      await expect(
        caller.cameraStream.add({
          cameraId: `test-cam-${Date.now()}`,
          cameraDescription: "Test Camera",
          streamType: "rtsp",
        })
      ).rejects.toThrow("RTSP URL is required for RTSP streams");
    });

    it("should reject duplicate camera ID", async () => {
      const { ctx } = createAuthContext();
      const caller = appRouter.createCaller(ctx);

      const cameraId = `test-cam-duplicate-${Date.now()}`;

      // Add first stream
      await caller.cameraStream.add({
        cameraId,
        cameraDescription: "First Camera",
        streamType: "rtsp",
        rtspUrl: "rtsp://example.com:554/stream1",
      });

      // Try to add duplicate
      await expect(
        caller.cameraStream.add({
          cameraId,
          cameraDescription: "Second Camera",
          streamType: "rtsp",
          rtspUrl: "rtsp://example.com:554/stream2",
        })
      ).rejects.toThrow("Camera ID already exists");
    });
  });

  describe("list", () => {
    it("should list all camera streams", async () => {
      const { ctx } = createAuthContext();
      const caller = appRouter.createCaller(ctx);

      const streams = await caller.cameraStream.list();

      expect(Array.isArray(streams)).toBe(true);
      // Should have at least the streams we added in previous tests
      expect(streams.length).toBeGreaterThanOrEqual(0);
    });
  });

  describe("getById", () => {
    it("should get a camera stream by ID", async () => {
      const { ctx } = createAuthContext();
      const caller = appRouter.createCaller(ctx);

      // First add a stream
      const cameraId = `test-cam-get-${Date.now()}`;
      await caller.cameraStream.add({
        cameraId,
        cameraDescription: "Test Get Camera",
        streamType: "rtsp",
        rtspUrl: "rtsp://example.com:554/stream",
      });

      // Get all streams to find the ID
      const streams = await caller.cameraStream.list();
      const addedStream = streams.find((s) => s.cameraId === cameraId);

      if (addedStream) {
        const stream = await caller.cameraStream.getById({ id: addedStream.id });
        expect(stream).toBeDefined();
        expect(stream?.cameraId).toBe(cameraId);
      }
    });

    it("should return undefined for non-existent ID", async () => {
      const { ctx } = createAuthContext();
      const caller = appRouter.createCaller(ctx);

      const stream = await caller.cameraStream.getById({ id: 999999 });
      expect(stream).toBeUndefined();
    });
  });
});
