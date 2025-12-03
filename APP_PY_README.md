# app.py - Camera Stream Receiver

This Python script receives camera stream data from the Camera Stream Manager and prints it to the console.

## Requirements

- Python 3.8 or higher
- pip (Python package installer)

## Installation

1. Install the required Python packages:

```bash
pip install -r requirements.txt
```

Or install individually:

```bash
pip install fastapi uvicorn pydantic
```

## Running the Server

Start the app.py server:

```bash
python3 app.py
```

The server will start on `http://localhost:8000`

You should see output like:
```
================================================================================
🚀 Starting Camera Stream Receiver
================================================================================
Server URL:         http://localhost:8000
API Endpoint:       http://localhost:8000/api/camera-stream
Health Check:       http://localhost:8000/health
================================================================================
```

## How It Works

When you add a new camera stream through the Camera Stream Manager web interface:

1. The stream data is saved to the database
2. The data is automatically sent to `http://localhost:8000/api/camera-stream`
3. The app.py server receives the data and prints it to the console

### Example Output

When a camera is added, you'll see output like this:

```
================================================================================
📹 NEW CAMERA STREAM RECEIVED
================================================================================
Camera ID:          CAM-001
Description:        Front entrance camera
Stream Type:        RTSP
RTSP URL:           rtsp://192.168.1.100:554/stream
Received at:        2025-12-01 17:45:30
================================================================================
```

## Configuration

By default, the Camera Stream Manager sends data to `http://localhost:8000`.

If you want to run app.py on a different host or port, you need to:

1. Modify the app.py server settings:
   ```python
   uvicorn.run(app, host="0.0.0.0", port=YOUR_PORT, log_level="info")
   ```

2. Set the `APP_PY_URL` environment variable in the Camera Stream Manager:
   - Go to Management UI → Settings → Secrets
   - Add: `APP_PY_URL` = `http://your-host:your-port`

## API Endpoints

### POST /api/camera-stream
Receives camera stream data and prints it to console.

**Request Body:**
```json
{
  "camera_id": "CAM-001",
  "camera_description": "Front entrance",
  "stream_type": "rtsp",
  "rtsp_url": "rtsp://example.com:554/stream",
  "video_url": null
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Camera stream 'CAM-001' received and printed",
  "camera_id": "CAM-001"
}
```

### GET /
Root endpoint - returns service status

### GET /health
Health check endpoint for monitoring

## Testing

You can test the endpoint manually using curl:

```bash
curl -X POST http://localhost:8000/api/camera-stream \
  -H "Content-Type: application/json" \
  -d '{
    "camera_id": "TEST-001",
    "camera_description": "Test camera",
    "stream_type": "rtsp",
    "rtsp_url": "rtsp://test.example.com:554/stream"
  }'
```

## Notes

- The app.py server only prints received data - it does not process, store, or forward it
- If app.py is not running when a camera is added, the stream will still be saved in the database
- The Camera Stream Manager will log an error but will not block the user from adding streams
- You can extend app.py to add your own processing logic as needed
