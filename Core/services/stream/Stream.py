import cv2
import time
import threading
import json
import uuid
import numpy as np

from dataclasses import dataclass
from kafka import KafkaProducer
from Core.common.frame_utils import encode_base64

@dataclass
class Camera:
    id: str
    description: str
    url: str 
    use_test_video: bool = False
    test_video_path: str | None = None
    frame_size = (320, 320)
    fps: float = 0


class CameraWorker(threading.Thread):
    def __init__(self, camera: Camera, kafka_bootstrap: str, topic: str):
        super().__init__(daemon=True)
        self.camera = camera
        self.topic = topic
        self.running = True

        # Create Kafka Producer
        self.producer = KafkaProducer(
        bootstrap_servers=kafka_bootstrap,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        retries=3,
        linger_ms=5,
        max_in_flight_requests_per_connection=5,
        api_version=(2, 5, 0)  # <— IMPORTANT FIX
    )
        
    def run(self):
        source = (
            self.camera.test_video_path
            if self.camera.use_test_video and self.camera.test_video_path
            else self.camera.url
        )

        cap = cv2.VideoCapture(source)
        
        if not cap.isOpened():
            print(f"[Camera {self.camera.id}] Cannot open stream from {source}")
            return

        while self.running:
            ret, frame = cap.read()
            if not ret:
                continue

            if self.camera.frame_size:
                frame = cv2.resize(frame, self.camera.frame_size)
            
            ok, jpg = cv2.imencode(".jpg", frame)
            
            frame_id = str(uuid.uuid4())
            frame_time = time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime())
            
            msg = {
                "camera_id": 0,
                "camera_description": "test",
                "frame_id": frame_id,
                "frame_time": frame_time,
                "frame": encode_base64(frame),
            }
            try:
                self.producer.send(self.topic, value=msg)
            except Exception as e:
                print(f"[Camera {self.camera.id}] Kafka send error: {e}")
            
            cv2.imshow(f"frame-{self.camera.id}", frame)
            cv2.waitKey(1)
            
        cap.release()
        self.producer.flush()
        self.producer.close()

    def stop(self):
        self.running = False
