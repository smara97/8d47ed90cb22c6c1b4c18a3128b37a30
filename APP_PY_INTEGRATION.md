# Integration with app.py

This document describes how to integrate the Camera Stream Manager with your `app.py` backend.

## Overview

When a user adds a camera stream (either RTSP or video upload), the data is stored in the database. To send this data to your `app.py` backend, you need to implement an HTTP endpoint in `app.py` and update the tRPC mutation in this project.

## Current Implementation

Currently, the `cameraStream.add` mutation in `server/routers.ts` has a placeholder comment:

```typescript
// TODO: Send data to app.py here
```

## Integration Steps

### 1. Create an Endpoint in app.py

Add an endpoint in your `app.py` to receive camera stream data:

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class CameraStreamData(BaseModel):
    camera_id: str
    camera_description: str | None
    stream_type: str  # "rtsp" or "video"
    rtsp_url: str | None
    video_url: str | None

@app.post("/api/camera-stream")
async def receive_camera_stream(data: CameraStreamData):
    """
    Endpoint to receive camera stream data from the Camera Stream Manager
    """
    print(f"Received camera stream: {data.camera_id}")
    
    # Process the stream data here
    # For example:
    # - Start processing the RTSP stream
    # - Download and process the video file
    # - Store metadata in your database
    
    return {"status": "success", "message": "Stream received"}
```

### 2. Update the tRPC Mutation

In `server/routers.ts`, replace the TODO comment with an HTTP request to your `app.py` endpoint:

```typescript
// After creating the stream in the database
await createCameraStream(streamData);

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
  }
} catch (error) {
  console.error("Error sending data to app.py:", error);
  // Note: We don't throw here to avoid blocking the user flow
  // The stream is already saved in the database
}

return { success: true, cameraId };
```

### 3. Configure Environment Variables

Add the `APP_PY_URL` environment variable to your project:

1. Go to the Management UI → Settings → Secrets
2. Add a new secret:
   - Key: `APP_PY_URL`
   - Value: Your app.py URL (e.g., `http://localhost:8000` or `https://your-app.com`)

Alternatively, you can use the `webdev_request_secrets` tool to prompt for this configuration.

### 4. Data Format

The data sent to `app.py` will have the following structure:

```json
{
  "camera_id": "CAM-001",
  "camera_description": "Front entrance camera",
  "stream_type": "rtsp",
  "rtsp_url": "rtsp://example.com:554/stream",
  "video_url": null
}
```

For video uploads:

```json
{
  "camera_id": "CAM-002",
  "camera_description": "Parking lot camera",
  "stream_type": "video",
  "rtsp_url": null,
  "video_url": "https://storage.example.com/camera-videos/CAM-002-1234567890-video.mp4"
}
```

## Testing the Integration

1. Start your `app.py` server
2. Add the `APP_PY_URL` environment variable
3. Add a new camera stream through the web interface
4. Check your `app.py` logs to confirm the data was received

## Error Handling

The current implementation logs errors but does not block the user flow if `app.py` is unavailable. This ensures that:

- Camera streams are always saved to the database
- Users can continue using the application even if `app.py` is temporarily down
- You can implement retry logic or queue-based processing if needed

## Alternative: Webhook Approach

If you prefer a webhook-based approach, you can:

1. Store the `APP_PY_URL` in the database as a webhook configuration
2. Implement a background job that sends stream data to the webhook
3. Add retry logic for failed webhook deliveries

This approach provides better reliability and decoupling between the two systems.
