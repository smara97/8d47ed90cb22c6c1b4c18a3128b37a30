/**
 * Local file storage system for development
 * Stores files in the public directory and serves them via the dev server
 */

import { writeFile, mkdir } from "fs/promises";
import { join } from "path";
import { randomBytes } from "crypto";

const UPLOAD_DIR = join(process.cwd(), "client", "public", "uploads");

/**
 * Initialize upload directory
 */
async function ensureUploadDir() {
  try {
    await mkdir(UPLOAD_DIR, { recursive: true });
  } catch (error) {
    console.error("Failed to create upload directory:", error);
  }
}

/**
 * Generate a unique filename
 */
function generateFileName(originalName: string): string {
  const timestamp = Date.now();
  const random = randomBytes(4).toString("hex");
  const ext = originalName.split(".").pop() || "bin";
  return `${timestamp}-${random}.${ext}`;
}

/**
 * Store file locally and return public URL
 */
export async function localStoragePut(
  fileName: string,
  data: Buffer | Uint8Array | string,
  contentType = "application/octet-stream"
): Promise<{ key: string; url: string }> {
  await ensureUploadDir();

  const uniqueFileName = generateFileName(fileName);
  const filePath = join(UPLOAD_DIR, uniqueFileName);
  
  // Convert string to Buffer if needed
  const buffer = typeof data === "string" ? Buffer.from(data) : Buffer.from(data);
  
  await writeFile(filePath, buffer);

  // Return public URL path
  const url = `/uploads/${uniqueFileName}`;
  const key = `uploads/${uniqueFileName}`;

  console.log(`[LocalStorage] File saved: ${key}`);
  
  return { key, url };
}

/**
 * Get file URL (for local storage, just return the public path)
 */
export async function localStorageGet(relKey: string): Promise<{ key: string; url: string }> {
  const key = relKey.replace(/^\/+/, "");
  const url = `/${key}`;
  return { key, url };
}
