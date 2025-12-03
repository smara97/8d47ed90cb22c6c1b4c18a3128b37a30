import { COOKIE_NAME } from "@shared/const";
import { getSessionCookieOptions } from "./_core/cookies";
import { systemRouter } from "./_core/systemRouter";
import { publicProcedure, protectedProcedure, router } from "./_core/trpc";
import { z } from "zod";
import { InsertCameraStream } from "../drizzle/schema";

export const appRouter = router({
    // if you need to use socket.io, read and register route in server/_core/index.ts, all api should start with '/api/' so that the gateway can route correctly
  system: systemRouter,
  auth: router({
    me: publicProcedure.query(opts => opts.ctx.user),
    logout: publicProcedure.mutation(({ ctx }) => {
      const cookieOptions = getSessionCookieOptions(ctx.req);
      ctx.res.clearCookie(COOKIE_NAME, { ...cookieOptions, maxAge: -1 });
      return {
        success: true,
      } as const;
    }),
  }),

  cameraStream: router({
    // Add a new camera stream
    add: publicProcedure
      .input(
        z.object({
          cameraId: z.string().min(1, "Camera ID is required"),
          cameraDescription: z.string().optional(),
          streamType: z.enum(["rtsp", "video"]),
          rtspUrl: z.string().optional(),
          videoFile: z.object({
            url: z.string(),
            fileKey: z.string(),
          }).optional(),
        })
      )
      .mutation(async ({ ctx, input }) => {
        const { cameraId, cameraDescription, streamType, rtspUrl, videoFile } = input;

        console.log("[AddStream] Received input:", { cameraId, streamType, videoFile });

        // Validate input based on stream type
        if (streamType === "rtsp" && !rtspUrl) {
          throw new Error("RTSP URL is required for RTSP streams");
        }
        if (streamType === "video" && !videoFile) {
          throw new Error("Video file is required for video streams");
        }

        // Check if camera ID already exists
        const { getCameraStreamByCameraId, createCameraStream } = await import("./db");
        const existing = await getCameraStreamByCameraId(cameraId);
        if (existing) {
          throw new Error("Camera ID already exists");
        }

        // Create the stream
        const streamData: InsertCameraStream = {
          cameraId,
          cameraDescription: cameraDescription || null,
          streamType,
          rtspUrl: streamType === "rtsp" ? rtspUrl : null,
          videoUrl: streamType === "video" ? videoFile?.url : null,
          videoFileKey: streamType === "video" ? videoFile?.fileKey : null,
          userId: ctx.user?.id || 1, // Default to user ID 1 for local development
        };

        console.log("[AddStream] Creating stream with data:", streamData);
        await createCameraStream(streamData);
        console.log("[AddStream] Stream created successfully");

        // Send data to app.py
        try {
          const appPyUrl = process.env.APP_PY_URL || "http://localhost:8000";
          const response = await fetch(`${appPyUrl}/api/camera-stream`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              camera_id: streamData.cameraId,
              camera_description: streamData.cameraDescription,
              stream_type: streamData.streamType,
              rtsp_url: streamData.rtspUrl,
              video_url: streamData.videoUrl,
            }),
          });

          if (!response.ok) {
            console.error("Failed to send data to app.py:", await response.text());
          } else {
            console.log("Successfully sent camera data to app.py:", cameraId);
          }
        } catch (error) {
          console.error("Error sending data to app.py:", error);
          // Note: We don't throw here to avoid blocking the user flow
          // The stream is already saved in the database
        }

        return { success: true, cameraId };
      }),

    // List all camera streams
    list: publicProcedure.query(async () => {
      const { getAllCameraStreams } = await import("./db");
      return await getAllCameraStreams();
    }),

    // Get a single camera stream by ID
    getById: publicProcedure
      .input(z.object({ id: z.number() }))
      .query(async ({ input }) => {
        const { getCameraStreamById } = await import("./db");
        return await getCameraStreamById(input.id);
      }),

    // Upload video file and return URL
    uploadVideo: publicProcedure
      .input(
        z.object({
          fileName: z.string(),
          fileData: z.string(), // Base64 encoded file data
          contentType: z.string(),
          cameraId: z.string(),
        })
      )
      .mutation(async ({ input }) => {
        const { fileName, fileData, contentType, cameraId } = input;
        
        // Decode base64 to buffer
        const buffer = Buffer.from(fileData, "base64");
        
        // Upload to local storage
        const { localStoragePut } = await import("./localStorage");
        const { url, key: fileKey } = await localStoragePut(fileName, buffer, contentType);
        
        return { url, fileKey };
      }),
  }),
});

export type AppRouter = typeof appRouter;
