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
        model_path: str = './models/yolo11n.pt',
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
        
        self.graph_scene = SceneGraphBuilder()


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
                "bbox": [float(box[0]), float(box[1]), float(box[2]), float(box[3])],
                "width": float(box[2] - box[0]),
                "height": float(box[3] - box[1]),
            })

        return detections, self.graph_scene.build(detections)

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
            detections, relations = self._process_results(result)
            outputs.append(
                {
                    'detections': detections,
                    'relations': relations
                }
            )
            
        return outputs

class SceneGraphBuilder:
    def __init__(self, iou_threshold=0.2, near_threshold=70, above_threshold=40):
        self.iou_threshold = iou_threshold
        self.near_threshold = near_threshold
        self.above_threshold = above_threshold

    def _center(self, bbox):
        x1, y1, x2, y2 = bbox
        return ( (x1+x2)/2, (y1+y2)/2 )

    def _distance(self, c1, c2):
        return np.linalg.norm(np.array(c1) - np.array(c2))

    def _relation(self, obj1, obj2):
        """ Determine relationship between two objects """
        c1 = self._center(obj1["bbox"])
        c2 = self._center(obj2["bbox"])

        dist = self._distance(c1, c2)

        rels = []

        # near
        if dist < self.near_threshold:
            rels.append("near")

        # left / right
        if c1[0] < c2[0]:
            rels.append("left_of")
        else:
            rels.append("right_of")

        # above / below
        if c1[1] < c2[1]:
            rels.append("above")
        else:
            rels.append("below")

        return rels

    def build(self, detections):
        """
        detections: list of
        {
          "class_id": 0
          "class_name": "person",
          "bbox": [x1, y1, x2, y2],
          "confidence": 0.9
        }
        """
        objects = []
        relations = []

        # 1) Convert detections → objects
        for idx, det in enumerate(detections):
            objects.append({
                "object_idx": idx,
                "class_id": det["class_id"],
                "class_name": det["class_name"],
                "bbox": det["bbox"],
                "confidence": det["confidence"],
            })

        # 2) Build relations pairwise
        for i in range(len(objects)):
            for j in range(i+1, len(objects)):
                obj1 = objects[i]
                obj2 = objects[j]

                rels = self._relation(obj1, obj2)

                relations.append({
                    "subject_idx": obj1["object_idx"],
                    "object_idx": obj2["object_idx"],
                    "relations": rels
                })

        # Final scene graph structure
        scene_graph = {
            "objects": objects,
            "relations": relations
        }

        return scene_graph

if __name__=='__main__':
    detector = ObjectsDetector('./models/yolo11n.pt')
    