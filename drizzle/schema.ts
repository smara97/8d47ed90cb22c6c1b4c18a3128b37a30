import { int, mysqlEnum, mysqlTable, text, timestamp, varchar } from "drizzle-orm/mysql-core";

/**
 * Core user table backing auth flow.
 * Extend this file with additional tables as your product grows.
 * Columns use camelCase to match both database fields and generated types.
 */
export const users = mysqlTable("users", {
  /**
   * Surrogate primary key. Auto-incremented numeric value managed by the database.
   * Use this for relations between tables.
   */
  id: int("id").autoincrement().primaryKey(),
  /** Manus OAuth identifier (openId) returned from the OAuth callback. Unique per user. */
  openId: varchar("openId", { length: 64 }).notNull().unique(),
  name: text("name"),
  email: varchar("email", { length: 320 }),
  loginMethod: varchar("loginMethod", { length: 64 }),
  role: mysqlEnum("role", ["user", "admin"]).default("user").notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
  lastSignedIn: timestamp("lastSignedIn").defaultNow().notNull(),
});

export type User = typeof users.$inferSelect;
export type InsertUser = typeof users.$inferInsert;

/**
 * Camera streams table for storing RTSP URLs or uploaded video files
 */
export const cameraStreams = mysqlTable("camera_streams", {
  id: int("id").autoincrement().primaryKey(),
  cameraId: varchar("camera_id", { length: 128 }).notNull().unique(),
  cameraDescription: text("camera_description"),
  streamType: mysqlEnum("stream_type", ["rtsp", "video"]).notNull(),
  rtspUrl: text("rtsp_url"), // For RTSP streams
  videoUrl: text("video_url"), // For uploaded videos (S3 URL)
  videoFileKey: text("video_file_key"), // S3 file key for uploaded videos
  userId: int("user_id").notNull(), // Owner of the stream
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().onUpdateNow().notNull(),
});

export type CameraStream = typeof cameraStreams.$inferSelect;
export type InsertCameraStream = typeof cameraStreams.$inferInsert;