import subprocess
import sys
import threading

from pathlib import Path


# List of services to run: (name_for_logs, module_path)
SERVICES = [
    ("ingestion", "Core.services.ingestion.main"),
    ("captioner", "Core.services.captioner.main"),
    ("detections", "Core.services.detections.main"),
    ("ocr", "Core.services.ocr.main"),
    ("aggregate", "Core.services.aggregate.main"),
]

def run_services() -> None:
    # Project root = directory that contains Core/
    project_root = Path(__file__).resolve().parent.parent
    processes = []

    for name, module in SERVICES:
        print(f"[run_services] starting {name} ({module})")
        p = subprocess.Popen(
            [sys.executable, "-m", module],
            cwd=str(project_root),
        )
        processes.append(p)

    print("[run_services] all services started. Press Ctrl+C to stop.")
    try:
        for p in processes:
            p.wait()
    except KeyboardInterrupt:
        print("[run_services] stopping services...")
        for p in processes:
            p.terminate()


if __name__ == "__main__":
    
    number_workers = 3
    
    threads = [threading.Thread(target=run_services) for _ in range(number_workers)]
    for thread in threads:
        thread.start()