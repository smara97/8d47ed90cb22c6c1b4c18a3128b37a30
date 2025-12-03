#!/usr/bin/env python3
"""
app.py - Camera Stream Receiver

This script receives camera stream data from the Camera Stream Manager
and prints it to the console. No other operations are performed.

Usage:
    python3 app.py

The server will run on http://localhost:8000 by default.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import uvicorn
from datetime import datetime

from Core.services.stream.StreamManager import StreamManager

app = FastAPI(title="Camera Stream Receiver", version="1.0.0")
stream_manager = StreamManager()

class CameraStreamData(BaseModel):
    """Data model for camera stream information"""
    camera_id: str
    camera_description: Optional[str] = None
    stream_type: str  # "rtsp" or "video"
    rtsp_url: Optional[str] = None
    video_url: Optional[str] = None
    
    # def _dict__:
    #     return {}
    # TODO converet this class to json. then push this converted data to streaming service


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "running",
        "service": "Camera Stream Receiver",
        "timestamp": datetime.now().isoformat()
    }


@app.post("/api/camera-stream")
async def receive_camera_stream(data: CameraStreamData):
    """
    Endpoint to receive camera stream data from the Camera Stream Manager.
    This endpoint only prints the received data to the console.
    
    Args:
        data: CameraStreamData object containing stream information
        
    Returns:
        Success response with received camera ID
    """
    # Print separator line
    
    camera_info = {
        'camera_id': data.camera_id,
        'description': data.camera_description,
        'url': data.rtsp_url,
        'use_test': True if data.stream_type == "video" else  False,
        'video_url': data.video_url
    }
    
    stream_manager.add_camera(camera_info)
    
    return {
        "status": "success",
        "message": f"Camera stream '{data.camera_id}' received and printed",
        "camera_id": data.camera_id
    }


@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}


if __name__ == "__main__":
    print("\n" + "="*80)
    print("🚀 Starting Camera Stream Receiver")
    print("="*80)
    print("Server URL:         http://localhost:8000")
    print("API Endpoint:       http://localhost:8000/api/camera-stream")
    print("Health Check:       http://localhost:8000/health")
    print("="*80 + "\n")
    
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
