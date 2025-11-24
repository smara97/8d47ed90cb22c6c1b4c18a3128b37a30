import numpy as np

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
