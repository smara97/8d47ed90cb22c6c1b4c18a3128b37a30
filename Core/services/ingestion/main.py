from typing import Dict, Any

from Core.common.kafka_config import create_consumer, create_producer

INGESTION_TOPIC = "ingestion"
ANALYZE_TOPIC = "analyze"


class IngestionService:
    def __init__(self, group_id: str = "ingestion_group"):
        self.consumer = create_consumer(INGESTION_TOPIC, group_id=group_id)
        self.producer = create_producer()

    def transform_message(self, msg: Dict[str, Any]) -> Dict[str, Any]:
        """Transform raw ingestion message into analyze message (pass-through)."""
        # just normalize basic fields; keep all others as-is
        camera_id = msg.get("camera_id")
        camera_description = msg.get("camera_description")
        frame_id = msg.get("frame_id")
        frame_time = msg.get("frame_time")
        frame_b64 = msg.get("frame")

        analyze_msg: Dict[str, Any] = {
            "frame_id": frame_id,
            "camera_id": camera_id,
            "camera_description": camera_description,
            "timestamp": frame_time,
            "frame_time": frame_time,
            "frame": frame_b64,
        }

        # keep any extra metadata from the original message
        for k, v in msg.items():
            if k not in analyze_msg:
                analyze_msg.setdefault("extra", {})[k] = v

        return analyze_msg

    def run(self) -> None:
        print(f"[ingestion] Listening on topic '{INGESTION_TOPIC}'")
        for record in self.consumer:
            raw_msg = record.value  # dict from JSON
            try:
                out_msg = self.transform_message(raw_msg)
                key = str(out_msg.get("frame_id", "")) or None
                
                self.producer.send(
                    ANALYZE_TOPIC,
                    key=key,
                    value=out_msg,
                )
                self.producer.flush()
            except Exception as e:
                print(f"[ingestion] ERROR: {e}")


if __name__ == "__main__":
    IngestionService().run()
