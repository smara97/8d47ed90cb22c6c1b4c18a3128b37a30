from abc import ABC, abstractmethod
from typing import Dict, Any

from Core.common.kafka_config import create_consumer, create_producer

ANALYZE_TOPIC = "analyze"
AGGREGATE_TOPIC = "aggregate"


class BaseAnalyzerService(ABC):
    def __init__(self, service_name: str, group_id: str):
        self.service_name = service_name
        self.consumer = create_consumer(ANALYZE_TOPIC, group_id=group_id)
        self.producer = create_producer()

    @abstractmethod
    def analyze_frame(self, frame_msg: Dict[str, Any]) -> Dict[str, Any]:
        """Run the model and return result dict."""
        raise NotImplementedError

    def run(self) -> None:
        print(f"[{self.service_name}] Listening on topic '{ANALYZE_TOPIC}'")
        for msg in self.consumer:
            frame = msg.value  # dict from JSON
            try:
                result = self.analyze_frame(frame)
                out_msg = {
                    "frame_id": frame.get("frame_id"),
                    "camera_id": frame.get("camera_id"),
                    "timestamp": frame.get("timestamp"),
                    "extra": frame.get("extra", {}),
                    "service": self.service_name,  # detection, ocr, caption
                    "result": result,
                }
                self.producer.send(
                    AGGREGATE_TOPIC,
                    key=str(frame.get("frame_id", "")),
                    value=out_msg,
                )
                self.producer.flush()
                print(f"[{self.service_name}] processed frame {frame.get('frame_id')}")
            except Exception as e:
                # Add proper logging here
                print(f"[{self.service_name}] ERROR: {e}")
