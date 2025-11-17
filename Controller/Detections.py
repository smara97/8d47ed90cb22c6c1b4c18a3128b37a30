import os
import cv2
import torch
import numpy as np
from typing import List, Dict, Union, Optional
from ultralytics import YOLO



class ObjectsDetector:
    """
    Fully generalized YOLO Detector.
    Works with ANY YOLO model version (v5-v11, custom .pt).
    """
    def __init__(
        self,
        model_path: str,
        device: Optional[str] = None,
        conf: float = 0.25,
        iou: float = 0.45,
        imgsz: int = 640,
        classes: Optional[List[int]] = None,
    ):
        """
        :param model_path: Path or name (yolov8n.pt, yolo11x.pt, custom.pt)
        :param device: "cuda" / "cpu" / None (auto)
        :param conf: Confidence threshold
        :param iou: IoU threshold for NMS
        :param imgsz: Inference image size
        :param classes: Filter specific classes (None = ALL)
        """
        self.model = YOLO(model_path)

        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")
        self.model.to(self.device)

        self.conf = conf
        self.iou = iou
        self.imgsz = imgsz
        self.classes = classes

        self.names = self.model.model.names


    def _process_results(self, results) -> List[Dict]:
        """
        Convert YOLO result to a clean unified format.
        Returns ALL OBJECTS.
        """
        detections = []

        if not results:
            return detections

        result = results[0]

        if result.boxes is None or len(result.boxes) == 0:
            return detections

        boxes = result.boxes.xyxy.cpu().numpy()
        confs = result.boxes.conf.cpu().numpy()
        clss = result.boxes.cls.cpu().numpy().astype(int)

        for box, cf, cls_id in zip(boxes, confs, clss):
            detections.append({
                "class_id": int(cls_id),
                "class_name": self.names[int(cls_id)],
                "confidence": float(cf),
                "bbox": {
                    "x1": float(box[0]),
                    "y1": float(box[1]),
                    "x2": float(box[2]),
                    "y2": float(box[3]),
                    "width": float(box[2] - box[0]),
                    "height": float(box[3] - box[1]),
                }
            })

        return detections

    @torch.inference_mode()
    def infer_batch(self, frames: list):
        """
        frames: list of np.array (H,W,3) in BGR or RGB
        return: list of detections per frame
        """
        if not frames:
            return []

        
        results = self.model(frames, verbose=False)
        
        outputs = []
        for result in results:
            outputs.append(self._process_results(result))
        return outputs

if __name__=='__main__':
    detector = ObjectsDetector('./models/yolo11n.pt')
    