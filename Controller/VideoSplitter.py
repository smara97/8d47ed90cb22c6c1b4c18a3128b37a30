import numpy as np
from typing import Dict, Any, List
from sklearn.metrics.pairwise import cosine_similarity


def cosine(a, b):
    if a is None or b is None:
        return 0.0
    a = np.array(a).reshape(1, -1)
    b = np.array(b).reshape(1, -1)
    return cosine_similarity(a, b)[0][0]


def jaccard_similarity(list1, list2):
    if not list1 or not list2:
        return 0.0
    s1, s2 = set(list1), set(list2)
    return len(s1 & s2) / len(s1 | s2)


class VideoSplitter:
    def __init__(self, threshold: float = 0.65):
        self.threshold = threshold
        self.last_frame_data = None
        self.current_segment = []
        self.segments: List[List[Dict[str, Any]]] = []

    def _compute_similarity(self, a, b):
        """Compute semantic similarity between two frames"""
        
        # Image vector similarity
        img_sim = cosine(a["image_vector"], b["image_vector"])

        # Caption text vector similarity
        txt_sim = cosine(a["text_vector"], b["text_vector"])

        # Object similarity
        objects_a = [o['class_name'] for o in a["detections"]]
        objects_b = [o['class_name'] for o in b["detections"]]
        obj_sim = jaccard_similarity(objects_a, objects_b)

        # OCR similarity (jaccard)
        ocr_sim = jaccard_similarity(a["ocr"], b["ocr"])

        # Weighted score
        final_score = (
            0.45 * img_sim +
            0.30 * txt_sim +
            0.15 * obj_sim +
            0.10 * ocr_sim
        )

        return final_score

    def add_frame(self, frame_info: Dict[str, Any]):
        """
        frame_info = {
            "frame_id": int,
            "detections": [...],
            "captions": "...",
            "ocr": [...],
            "image_vector": [...],
            "text_vector": [...]
        }
        """

        if self.last_frame_data is None:
            # First frame ever → start a new segment
            self.last_frame_data = frame_info
            self.current_segment.append(frame_info)
            return False  # No split

        # Compute similarity with previous frame
        score = self._compute_similarity(frame_info, self.last_frame_data)

        if score < self.threshold:
            # SPLIT → save old segment and start new
            self.segments.append(self.current_segment)
            self.current_segment = [frame_info]
            print(f"[SPLIT] New segment started. Score={score:.2f}")
            self.last_frame_data = frame_info
            return True  # Split happened

        # No split
        self.current_segment.append(frame_info)
        self.last_frame_data = frame_info
        return False

    def finalize(self):
        """Call at the end of video to push last segment"""
        if self.current_segment:
            self.segments.append(self.current_segment)
        return self.segments
