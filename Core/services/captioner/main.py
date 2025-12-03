from typing import Dict, Any

from Core.services.base_service import BaseAnalyzerService
from .Captioner import ImageCaption


class CaptionerService(BaseAnalyzerService):
    def __init__(self):
        super().__init__(service_name="caption", group_id="captioner_group")
        self.model = ImageCaption()

    def analyze_frame(self, frame_msg: Dict[str, Any]) -> Dict[str, Any]:
        return self.model.infer_batch(frame_msg)

if __name__ == "__main__":
    CaptionerService().run()
