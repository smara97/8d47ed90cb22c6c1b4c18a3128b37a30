import os
os.environ["TORCHVISION_DISABLE_NMS_CUDA"] = "1"

from Controller.ImageEmbeddings import Vecorization
from Controller.OCR import get_ocr_docs
from Controller.Detections import ObjectsDetector
from Controller.Captioner import ImageCaption


if __name__=='__main__':
    
    import cv2
    import json
    from Controller.VideoSplitter import VideoSplitter
    
    cap = cv2.VideoCapture("./videos/Feline Interpretive Dance for Treats.mp4")
    splitter = VideoSplitter(threshold=0.65)
    
    
    vectorize = Vecorization()
    detector = ObjectsDetector('./models/yolo11n.pt')
    captioner = ImageCaption()
    
    batch = []
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        batch.append(frame)
        
        if len(batch) == 32:
            detections = detector.infer_batch(batch)
            captions = captioner.infer_batch(batch)
            images_vectors = vectorize.infer_images_batch(batch)
            texts_vectors = vectorize.infer_texts_batch(captions)
            ocrs = get_ocr_docs(batch)
            
            for i in range(32):
                frame_info = {
                    "frame_id": i,
                    "detections": detections[i],
                    "captions": captions[i],
                    "ocr": ocrs[i],
                    "image_vector": images_vectors[i].cpu().tolist(),
                    "text_vector": texts_vectors[i].cpu().tolist()
                }

            splitter.add_frame(frame_info)
            print(f"Total Segments: {len(splitter.segments)}")
                    
            batch = []    
    
    segments = splitter.finalize()
    print(f"Total Segments: {len(segments)}")