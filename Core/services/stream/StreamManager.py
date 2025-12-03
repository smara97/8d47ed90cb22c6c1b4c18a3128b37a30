import time
import threading
from typing import Dict, List

from Core.services.stream.Stream import Camera, CameraWorker


class StreamManager:
    def __init__(self, kafka_bootstrap: str = "localhost:9092", topic: str = "ingestion"):
        """
        Manages multiple camera workers.
        """
        self.cameras = []
        self.kafka_bootstrap = kafka_bootstrap
        self.topic = topic
        
        self.workers: Dict[str, CameraWorker] = {}
        self.monitor_running = True
        self.monitor_thread = threading.Thread(target=self._monitor_workers, daemon=True)
        self.monitor_thread.start()
        
    def add_camera(self, camera_info: dict):
        """
        camera_info = {
            'camera_id': data.camera_id,
            'description': data.camera_description,
            'url': data.rtsp_url,
            'use_test': True if data.stream_type == "video" else  False,
            'video_url': data.video_url
        }
        """
        camera = Camera(
            id=camera_info.get('camera_id'), 
            description=camera_info.get('description'),
            url=camera_info.get('url'),
            use_test_video=camera_info['use_test'],
            test_video_path=camera_info['video_url'],
            fps=20
        )
        
        self.cameras.append(camera)
        self._start_single_worker(camera=camera)

    def _start_single_worker(self, camera: Camera):
        worker = CameraWorker(
            camera=camera,
            kafka_bootstrap=self.kafka_bootstrap,
            topic=self.topic,
        )
        self.workers[camera.id] = worker
        worker.start()
        print(f"[StreamManager] Worker started: {camera.id}")

    def _monitor_workers(self):
        """
        Monitors workers & restarts them if needed.
        """
        while self.monitor_running:
            for cam_id, worker in list(self.workers.items()):
                if not worker.is_alive():
                    print(f"[StreamManager] Worker for {cam_id} stopped → Restarting...")
                    cam = worker.camera
                    self._start_single_worker(cam)
            time.sleep(10)

    def stop_all(self):
        self.monitor_running = False
        for worker in self.workers.values():
            worker.stop()
        print("[StreamManager] All workers stopped.")
        
    def stop_camera(self, camera_id):
        pass
