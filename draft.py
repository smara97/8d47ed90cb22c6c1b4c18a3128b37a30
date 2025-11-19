import os
os.environ["TORCHVISION_DISABLE_NMS_CUDA"] = "1"

from Controller.ImageEmbeddings import Vecorization
from Controller.OCR import get_ocr_docs
from Controller.Detections import ObjectsDetector
from Controller.Captioner import ImageCaption
from Controller.FramesSummary import VideoSummarizer
from Controller.SceneGraph import SceneGraphBuilder
from tqdm import tqdm

if __name__=='__main__':
    
    import cv2
    import json
    cap = cv2.VideoCapture("./videos/Feline Interpretive Dance for Treats.mp4")
    
    detector = ObjectsDetector('./models/yolo11n.pt')
    captioner = ImageCaption()
    summarizer  = VideoSummarizer()
    graph_builder = SceneGraphBuilder()
    
    batch_size = 316
    segment = 0
    frame_width = 640
    frame_height = 640
    fps = 30
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    
    while True:
        
        out = cv2.VideoWriter(f'./output/segments/segment-{segment}.mp4', fourcc, fps, (frame_width, frame_height))
        
        for i in tqdm(range(batch_size)):
            
            ret, frame = cap.read()
            if not ret:
                break
            
            detections = detector.infer_batch([frame])
            captions = captioner.infer_batch([frame])
            ocrs = get_ocr_docs([frame])
            
            frame_info = {
                "frame_id": i,
                "camera_id": 1,
                "detections": detections[0],
                'scene_graph': graph_builder.build(detections[0]),
                "captions": captions[0],
                "ocr": ocrs[0],
            }
            
            if i%20 == 0:
                batch_text = summarizer.process_frame(frame_info)
            
            frame = cv2.resize(frame, (frame_width, frame_height))
            out.write(frame)
            
            with open(f'./output/segments/segment-{segment}.txt', 'w+') as f:
                f.write(batch_text)
            
        
        summarizer.reset()
        segment+=1
        out.release()
        
        if not ret:
            break
                