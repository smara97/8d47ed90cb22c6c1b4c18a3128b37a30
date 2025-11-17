import time
import numpy as np
from Controller.StreamManager import StreamManager
from Controller.Stream import Camera
from Controller.ZMQFrameReceiver import ZMQBatchReceiver
from Controller.Detections import ObjectsDetector




if __name__=='__main__':    
    
    detector = ObjectsDetector('./models/yolo11n.pt')
    
    cameras = [
        Camera(
            id="cam1",
            description="Test",
            url="./videos/Feline Interpretive Dance for Treats.mp4"
        ),
        Camera(
            id="cam2",
            description="Test",
            url="./videos/Feline Interpretive Dance for Treats.mp4"
        ),
        Camera(
            id="cam3",
            description="Test",
            url="./videos/Feline Interpretive Dance for Treats.mp4"
        )
    ]
    
    stream_manger = StreamManager(cameras=cameras, zmq_push_address ='tcp://127.0.0.1:5555')
    stream_manger.start()
    
    receiver = ZMQBatchReceiver(bind_addr='tcp://127.0.0.1:5555')
    
    while True:
        
        tic = time.time()
        
        batch = receiver.get_batch()
        
        frames = [item['frame'] for item in batch]
        
        result = detector.infer_batch(frames)
        
        print(time.time() - tic)    
        
        
        