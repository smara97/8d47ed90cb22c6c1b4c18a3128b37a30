import zmq
import time
import cv2
import numpy as np
import msgpack
import msgpack_numpy as m

from queue import Queue
from threading import Thread, Lock
m.patch()


class ZMQBatchReceiver:
    """
    - Runs a background thread pulling frames from ZeroMQ PUSH sockets.
    - Stores incoming frames in an internal list buffer.
    - Allows Detector to request batches on demand using get_batch().
    """
    def __init__(
        self,
        bind_addr="tcp://*:5555",
    ):
        self.ctx = zmq.Context()
        self.socket = self.ctx.socket(zmq.PULL)
        self.socket.bind(bind_addr)

        self.current_batch = []
        self.current_batch_length = 0
        self.batches_queue = Queue()
        self.lock = Lock()
        
        self.running = True
        
        self.max_batch = 16

        self.thread = Thread(target=self._recv_loop, daemon=True)
        self.thread.start()
        
        self.monitor_thread = Thread(target=self._monitor, daemon=True)
        self.monitor_thread.start()
    
    def _monitor(self):
        while True:
            print("[ZMQBatchReceiver] Queue Length", self.batches_queue.qsize())
            time.sleep(5)
            
    def _recv_loop(self):
        while self.running:
            try:
                data = self.socket.recv(flags=zmq.NOBLOCK)
            except zmq.Again:
                time.sleep(0.001)
                continue

            packet = msgpack.loads(data)

            if packet.get("encoded", False):
                jpg = np.frombuffer(packet["frame"], dtype=np.uint8)
                frame = cv2.imdecode(jpg, cv2.IMREAD_COLOR)
            else:
                frame = packet["frame"]

            item = {
                "camera_id": packet["camera_id"],
                "timestamp": packet["timestamp"],
                "frame": frame
            }
            
            with self.lock:
                if self.current_batch_length < self.max_batch:
                    self.current_batch.append(item)
                    self.current_batch_length+=1
                    
                else:
                    self.batches_queue.put(self.current_batch)
                    self.current_batch = []
                    self.current_batch_length = 0

    def get_batch(self):
        """
        Returns a batch of frames with metadata:
            [
                {"camera_id": ..., "timestamp": ..., "frame": np.ndarray},
                ...
            ]
        """
        
        batch = []        
        with self.lock:
            if self.batches_queue.qsize():
                batch = self.batches_queue.get()
                
            else:
                batch = self.current_batch
                self.current_batch = []
                self.current_batch_length = 0
                 
        return batch

    def stop(self):
        self.running = False
        self.thread.join()
        self.socket.close()
        self.ctx.term()
