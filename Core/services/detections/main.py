from typing import Dict, Any

from Core.services.base_service import BaseAnalyzerService
from Core.common.frame_utils import decode_frame_from_base64
from .Detections import ObjectsDetector


class DetectionsService(BaseAnalyzerService):
    def __init__(self):
        super().__init__(service_name="detection", group_id="detections_group")
        self.model = ObjectsDetector()

    def analyze_frame(self, frame_msg: Dict[str, Any]) -> Dict[str, Any]:
        frame = frame_msg['frame']
        frame = decode_frame_from_base64(frame)
        return self.model.infer_batch([frame])


if __name__ == "__main__":
    DetectionsService().run()
