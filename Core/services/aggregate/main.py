import json
import os
import time
from pathlib import Path
from typing import Any, Dict

from Core.common.kafka_config import create_consumer

AGGREGATE_TOPIC = "aggregate"
RESULTS_DIR_NAME = "results"  # as requested: resultd/frame_key.json

REQUIRED_SERVICES = {"detection", "caption", "ocr"}


class AggregateService:
    def __init__(self, group_id: str = "aggregate_group") -> None:
        self.consumer = create_consumer(AGGREGATE_TOPIC, group_id=group_id)
        self.frames: Dict[str, Dict[str, Any]] = {}

        project_root = Path(__file__).resolve().parents[2]
        self.results_dir = project_root / RESULTS_DIR_NAME
        os.makedirs(self.results_dir, exist_ok=True)

    def _update_frame_state(self, msg: Dict[str, Any]) -> None:
        frame_id = str(msg.get("frame_id"))
        if not frame_id:
            return

        service = msg.get("service")
        result = msg.get("result")

        state = self.frames.setdefault(frame_id, {
            "meta": {
                "frame_id": frame_id,
                "camera_id": msg.get("camera_id"),
                "timestamp": msg.get("timestamp"),
                "extra": msg.get("extra", {}),
            },
            "services": {},
            "last_update": time.time(),
        })

        state["services"][service] = result
        state["last_update"] = time.time()

    def _maybe_flush_frame(self, frame_id: str) -> None:
        state = self.frames.get(frame_id)
        if not state:
            return

        services = state["services"]
        if not REQUIRED_SERVICES.issubset(services.keys()):
            return

        meta = state["meta"]

        # Extract pieces from services
        detection_result = services.get("detection")
        caption_result = services.get("caption")
        ocr_result = services.get("ocr")

        # Normalize detections: can be dict with key "detections" or a raw list
        if isinstance(detection_result, dict) and "detections" in detection_result:
            detections = detection_result.get("detections") or []
        elif isinstance(detection_result, list):
            detections = detection_result
        elif detection_result is None:
            detections = []
        else:
            # unknown shape, just wrap it so we don't crash
            detections = [detection_result]

        # captions: can be dict with "caption" or a plain string
        if isinstance(caption_result, dict) and "caption" in caption_result:
            captions_text = caption_result.get("caption")
        else:
            captions_text = caption_result

        # OCR may return list, dict with "texts", or plain string; normalize to string
        if isinstance(ocr_result, dict) and "texts" in ocr_result:
            texts = ocr_result["texts"]
            if isinstance(texts, list):
                ocr_text = "; ".join(
                    t.get("text", "") if isinstance(t, dict) else str(t) for t in texts
                )
            else:
                ocr_text = str(texts)
        elif isinstance(ocr_result, list):
            ocr_text = "; ".join(str(t) for t in ocr_result)
        else:
            ocr_text = str(ocr_result) if ocr_result is not None else ""

        aggregated = {
            "frame_id": meta.get("frame_id"),
            "camera_id": meta.get("camera_id"),
            "timestamp": meta.get("timestamp"),
            "extra": meta.get("extra", {}),
            "detections": detections,
            "captions": captions_text,
            "ocr": ocr_text,
        }

        # out_path = self.results_dir / f"{frame_id}.json"
        # with out_path.open("w", encoding="utf-8") as f:
        #     json.dump(aggregated, f, ensure_ascii=False, indent=4)

        # print(f"[aggregate] wrote {out_path}")

        # Remove frame from memory
        del self.frames[frame_id]

    def run(self) -> None:
        print(f"[aggregate] Listening on topic '{AGGREGATE_TOPIC}'")
        for record in self.consumer:
            msg = record.value
            try:
                self._update_frame_state(msg)
                frame_id = str(msg.get("frame_id"))
                self._maybe_flush_frame(frame_id)
            except Exception as e:
                print(f"[aggregate] ERROR: {e}")


if __name__ == "__main__":
    AggregateService().run()
