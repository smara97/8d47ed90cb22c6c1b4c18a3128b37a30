import time
import threading
from typing import Dict, List
from queue import Queue

from Controller.Stream import Camera, CameraWorker


class StreamManager:
    def __init__(self, cameras: List[Camera], zmq_push_address):
        """
        Manages multiple camera threads
        """
        self.cameras = cameras
        self.zmq_push_address = zmq_push_address

        self.workers: Dict[str, CameraWorker] = {}
        self.monitor_thread = threading.Thread(target=self._monitor_workers, daemon=True)
        self.monitor_running = True

    def start(self):
        """
        Start all camera threads + monitoring thread.
        """
        for cam in self.cameras:
            self._start_single_worker(cam)

        self.monitor_thread.start()
        print(f"[StreamManager] Started {len(self.workers)} camera workers.")

    
    def _start_single_worker(self, camera: Camera):
        worker = CameraWorker(camera=camera, zmq_push_address=self.zmq_push_address)
        self.workers[camera.id] = worker
        worker.start()
        print(f"[StreamManager] Worker started: {camera.id}")


    def _monitor_workers(self):
        """
        Background monitor:
        - Checks if worker thread is alive
        - If dead → restart it
        """
        while self.monitor_running:
            for cam_id, worker in list(self.workers.items()):
                if not worker.is_alive():
                    print(f"[StreamManager] Worker {cam_id} is DOWN. Restarting...")
                    cam = worker.camera
                    self._start_single_worker(cam)

            time.sleep(10)

   
    def stop_all(self):
        self.monitor_running = False

        for worker in self.workers.values():
            worker.stop()

        print("[StreamManager] All workers stopped.")

