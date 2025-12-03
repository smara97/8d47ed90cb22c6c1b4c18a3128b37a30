from typing import Dict, Any

from Core.services.base_service import BaseAnalyzerService
from Core.common.frame_utils import decode_frame_from_base64
from .OCR import EasyOCR


class OCRService(BaseAnalyzerService):
    def __init__(self):
        super().__init__(service_name="ocr", group_id="ocr_group")
        self.model = EasyOCR()

    def analyze_frame(self, frame_msg: Dict[str, Any]) -> Dict[str, Any]:
        frame = frame_msg.get('frame')
        frame = decode_frame_from_base64(frame)
        return self.model.analyze([frame])

if __name__ == "__main__":
    OCRService().run()
