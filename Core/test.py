import base64
import json
import time
import uuid
import threading

from queue import Queue
from kafka import KafkaProducer, KafkaConsumer

from Core.common.kafka_config import KAFKA_BOOTSTRAP_SERVERS

from Core.common.frame_utils import encode_base64
import cv2

INGESTION_TOPIC = "ingestion"
AGGREGATE_TOPIC = "aggregate"


def create_raw_producer() -> KafkaProducer:
    return KafkaProducer(
        bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
        value_serializer=lambda v: json.dumps(v).encode("utf-8"),
        key_serializer=lambda v: v.encode("utf-8") if v else None,
    )


def create_raw_consumer(topic: str, group_id: str) -> KafkaConsumer:
    return KafkaConsumer(
        topic,
        bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
        group_id=group_id,
        value_deserializer=lambda m: json.loads(m.decode("utf-8")),
        key_deserializer=lambda m: m.decode("utf-8") if m else None,
        enable_auto_commit=True,
        auto_offset_reset="earliest",
    )


def send_test_frame(frame) -> str:
    """Send one test frame message (black image) to the ingestion topic and return frame_id."""
    producer = create_raw_producer()

    frame_id = str(uuid.uuid4())
    frame_time = time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime())
    
    msg = {
        "camera_id": 0,
        "camera_description": "test",
        "frame_id": frame_id,
        "frame_time": frame_time,
        "frame": encode_base64(frame),
    }
    
    future = producer.send(INGESTION_TOPIC, key=str(frame_id), value=msg)
    try:
        metadata = future.get(timeout=5)
    except Exception as e:
        print(f"[test] ERROR sending to Kafka: {e}")

    producer.flush()
    producer.close()
    return frame_id

def get_result_of_frame(target_frame_id):
    """Listen on aggregate topic and print results for the given frame_id."""
    global number_frame
    global start_time
    consumer = create_raw_consumer(AGGREGATE_TOPIC, group_id="test_client_group")

    seen_services = set()
    
    for msg in consumer:
        value = msg.value
        frame_id = value.get("frame_id")
        service = value.get("service")
        if frame_id == target_frame_id:
            if service:
                seen_services.add(service)
                
        if len(seen_services) == 3:
            number_frame+=1
            print(f'[INFO] FPS: {number_frame/(time.time() - start_time)}')

    consumer.close()
    
def listen_for_results() -> None:
    
    while True:
        target_frame_id = frames_queue.get()
        
        if not target_frame_id:
            continue
        
        get_result_of_frame(target_frame_id)
        

if __name__ == "__main__":
    
    frames_queue = Queue()
    aggreaget_thread = threading.Thread(target=listen_for_results)
    aggreaget_thread.start()
    
    cap = cv2.VideoCapture('rtsp://0.tcp.in.ngrok.io:19140/mystream')
    
    start_time = time.time()
    number_frame = 0
    while True:
        ret, frame = cap.read()
        
        frame = cv2.resize(frame, (320, 320))
        if not ret:
            continue
        
        cv2.imshow("frame ya walllllllla", frame)
        cv2.waitKey(1)
        
        frame_id = send_test_frame(frame=frame)
        frames_queue.put(frame_id)

