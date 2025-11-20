import cv2
import time
import threading
import zmq
import numpy as np
import msgpack
import msgpack_numpy as m
m.patch()

from dataclasses import dataclass

@dataclass
class Camera:
    id: str
    description: str
    url: str
    frame_size = (640, 640)
    fps: float = 0



class CameraWorker(threading.Thread):
    def __init__(self, camera: Camera, zmq_push_address: str):
        super().__init__(daemon=True)
        self.camera = camera
        self.running = True
        
        self.ctx = zmq.Context()
        self.socket = self.ctx.socket(zmq.PUSH)
        self.socket.connect(zmq_push_address)

    def run(self):
        cap = cv2.VideoCapture(self.camera.url)
        if not cap.isOpened():
            print(f"[Camera {self.camera.id}] Cannot open stream")
            return
        
        while self.running:
            ret, frame = cap.read()
            if not ret:
                time.sleep(0.1)
                continue
            
            if self.camera.frame_size:
                frame = cv2.resize(frame, self.camera.frame_size)

            ok, jpg = cv2.imencode(".jpg", frame)
            if not ok:
                continue

            packet = {
                "camera_id": self.camera.id,
                "timestamp": time.time(),
                "encoded": True,
                "frame": jpg.tobytes()
            }

            data = msgpack.dumps(packet)
            self.socket.send(data)

        cap.release()

    def stop(self):
        self.running = False
        self.socket.close()
        self.ctx.term()
