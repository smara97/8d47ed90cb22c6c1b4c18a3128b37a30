# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project overview

This repo is an experimental **Video RAG** system built around two main workflows:

- A **real-time multi-camera pipeline** that ingests video streams, runs object detection, and pushes frames over ZeroMQ for batched inference.
- An **offline video summarization + RAG pipeline** that segments a video into narrative chunks, stores text summaries in Qdrant, and exposes a Gradio UI for question answering over the video.

There is no formal build or packaging configuration (no `pyproject.toml` / `requirements.txt` / Dockerfile). Everything is driven by Python entrypoint scripts and local data directories.

## Repository structure (high level)

- `app.py` – Entry script for the **real-time streaming object detection** demo.
- `rag_app.py` – Entry script for the **Video RAG + Gradio UI** over pre-generated video segments.
- `draft.py` – Offline script that processes a single video into semantic segments and narrative summaries for later RAG ingestion.
- `Controller/` – Core logic for vision and video understanding:
  - `Stream.py`, `StreamManager.py`, `ZMQFrameReceiver.py` – Camera abstraction, multi-camera management, and ZeroMQ-based frame batching.
  - `Detections.py`, `Captioner.py`, `OCR.py`, `ImageEmbeddings.py`, `SceneGraph.py`, `FramesSummary.py`, `VideoSplitter.py` – Object detection, captioning, OCR, embedding, scene-graph construction, frame-by-frame summarization, and semantic video segmentation utilities.
  - `llava/` – Bundled LLaVA implementation (treated as third-party code; avoid invasive edits unless necessary).
- `models/` – Local YOLO weight file(s), e.g. `yolo11n.pt` used by `ObjectsDetector`.
- `videos/` – Sample input videos (e.g. `Feline Interpretive Dance for Treats.mp4`).
- `output/` – Generated artifacts from processing, such as segmented clips and text summaries.
- `qdrant_data/`, `qdrant_video_db/` – Local Qdrant storage directories used by the RAG application.
- `src/` – Design and research notes, including Kafka vs ZeroMQ streaming analysis (background context, not executed code).

## Core workflows and data flow

### 1. Real-time streaming detection (`app.py` + streaming controllers)

- `app.py` defines multiple `Camera` instances (all currently pointed at the sample video) and a `StreamManager`:
  - `StreamManager` (`Controller/StreamManager.py`) owns a set of `CameraWorker` threads.
  - Each `CameraWorker` (`Controller/Stream.py`) reads from its camera URL using OpenCV, resizes frames, JPEG-encodes them, and pushes msgpack-encoded packets over a **ZeroMQ PUSH** socket.
- `ZMQBatchReceiver` (`Controller/ZMQFrameReceiver.py`) binds a **PULL** socket, receives packets in a background thread, decodes them back to `np.ndarray` frames, and builds batches up to `max_batch` (default 16).
- In the main loop inside `app.py`:
  - `receiver.get_batch()` retrieves a batch of frames.
  - `ObjectsDetector.infer_batch()` (`Controller/Detections.py`) runs YOLO (Ultralytics) on the batch and returns structured detection dictionaries.
  - Timing information is printed for latency diagnostics.

This pipeline is primarily for **throughput / latency experiments** with multi-camera ingestion and batch detection.

### 2. Offline segmentation + narrative summarization (`draft.py` and Controller utilities)

- `draft.py` processes a single video file from `./videos/` in batches of frames (`batch_size`), writing each batch as a clip plus a text summary:
  - Uses `ObjectsDetector` (YOLO) for per-frame detections.
  - Uses `ImageCaption` (`Controller/Captioner.py`, BLIP image captioning) for natural-language captions.
  - Uses `get_ocr_docs` (`Controller/OCR.py`, EasyOCR) for textual overlays in the video.
  - Uses `SceneGraphBuilder` (`Controller/SceneGraph.py`) to build a simple spatial relationship graph between detected objects.
  - Uses `VideoSummarizer` (`Controller/FramesSummary.py`) which wraps a `ChatOpenAI` client (Qwen-72B via HTTP) to maintain an evolving narrative summary across frames.
- For each batch, `draft.py` writes:
  - A video clip file to `output/segments/segment-{N}.mp4`.
  - A corresponding narrative text file to `output/segments/segment-{N}.txt`.
- `VideoSplitter` (`Controller/VideoSplitter.py`) is a standalone utility for **semantic segmentation** of frame metadata streams, using a weighted combination of image embeddings, caption embeddings, detected object classes, and OCR strings to decide when to start a new segment.

This workflow is CPU/GPU heavy (YOLO, BLIP, EasyOCR, LLM calls) and assumes access to the local YOLO weights and a reachable LLM HTTP endpoint.

### 3. Video RAG and Gradio UI (`rag_app.py`)

- `AnalyticsRagVideo` in `rag_app.py` implements the RAG side over pre-generated segments:
  - Expects text segment files in `output/video_segments/segment-*.txt` and corresponding `segment-*.mp4` clips.
  - Uses `SentenceTransformer` to embed the segment texts.
  - Stores vectors + payloads (`segment_name`, `text`, `video_path`) in a local Qdrant collection `video_segments` under `./qdrant_video_db`.
  - Uses a `ChatOpenAI` client (again targeting a Qwen HTTP endpoint) as the generative LLM.
- `ingest_segments()` scans the segments folder, builds embeddings, and upserts them into Qdrant using `PointStruct` objects.
- `retrieve()` performs a vector search for the user query and returns the top-K segment payloads.
- `rag_answer()`:
  - Wraps retrieved segments into a textual context block.
  - Sends a system + human prompt to the LLM to obtain an answer.
  - Returns the natural-language answer along with the selected segment metadata.
- `build_gradio()`/`launch()` define and serve a Gradio UI with:
  - A query textbox.
  - A text panel for the RAG answer.
  - An HTML panel with embedded `<video>` tags for relevant segments.
  - A raw debug pane listing scores, paths, and texts for retrieved segments.

## Running the key scripts

> This repo assumes a working Python 3 environment with CUDA available for best performance, but most components will also run on CPU (albeit much slower).

### 1. Environment and dependencies

There is no `requirements.txt` yet. Dependencies are inferred from imports and include (non-exhaustive):

- Core: `numpy`, `opencv-python`, `msgpack`, `msgpack-numpy`, `pyzmq`, `tqdm`, `chardet`.
- Vision models: `torch`, `ultralytics`, `transformers`, `sentence-transformers`, `easyocr`.
- LLM / RAG: `langchain-openai`, `langchain-core`, `qdrant-client`, `gradio`.

A typical one-shot install for local experimentation:

```bash
pip install numpy opencv-python msgpack msgpack-numpy pyzmq tqdm chardet \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    ultralytics transformers sentence-transformers easyocr \
    qdrant-client gradio langchain-openai langchain-core
```

Adjust the PyTorch index URL for your CUDA/CPU setup as appropriate.

### 2. Real-time multi-camera detection demo

Run the streaming YOLO demo:

```bash
python app.py
```

Behavior and expectations:

- Spawns three `CameraWorker` threads all reading from `./videos/Feline Interpretive Dance for Treats.mp4`.
- Streams JPEG-encoded frames over ZeroMQ (`tcp://127.0.0.1:5555`).
- `ZMQBatchReceiver` assembles batches and feeds them into `ObjectsDetector.infer_batch()` using `./models/yolo11n.pt`.
- Prints per-batch latency; does **not** persist results or show a UI.

If you change camera URLs to RTSP or other live streams, keep in mind:

- `Camera.url` is passed directly to `cv2.VideoCapture`.
- `Camera.frame_size` controls resize behavior before encoding.
- `StreamManager` will auto-restart dead workers.

### 3. Offline video segmentation + summarization

Generate narrative segments from the sample video:

```bash
python draft.py
```

This will:

- Read `./videos/Feline Interpretive Dance for Treats.mp4` frame by frame.
- Run YOLO detection, BLIP captioning, EasyOCR, scene-graph building, and LLM-based summarization.
- Write segment clips and corresponding narrative text to `./output/segments/segment-{N}.mp4` and `.txt`.

Notes:

- `draft.py` sets `TORCHVISION_DISABLE_NMS_CUDA=1` to avoid known TorchVision NMS CUDA issues.
- The summarizer uses a remote Qwen endpoint (see `VideoSummarizer` configuration); update the `base_url`/`api_key`/`model` if your environment differs.

### 4. Video RAG Gradio app

Once you have text + video segments prepared under `output/video_segments/` (or after copying/renaming from `output/segments/` to match that layout), run:

```bash
python rag_app.py
```

The default `__main__` block will:

1. Instantiate `AnalyticsRagVideo` with Qdrant path `./qdrant_video_db`.
2. Call `ingest_segments()` to build or refresh the `video_segments` collection.
3. Launch a Gradio server on `0.0.0.0:7860`.

Key configuration points inside `AnalyticsRagVideo.__init__`:

- `segments_folder` – Where `segment-*.txt` and `.mp4` pairs are read from.
- `qdrant_path` – Local Qdrant DB directory; can be safely deleted to reset the DB.
- `base_url`, `api_key`, `llm_model` – HTTP endpoint + credentials for the backing LLM.

## Tests and quick smoke checks

There is **no formal test suite** (no `tests/` directory, `pytest` config, or test runner scripts). To sanity-check individual components:

- `python Controller/Detections.py` – Instantiates `ObjectsDetector` with `./models/yolo11n.pt` and is a good starting point for validating YOLO + device configuration.
- `python Controller/ImageEmbeddings.py` – Contains a minimal `__main__` harness for CLIP-based embedding; may require small fixes (e.g., method naming) if you intend to use it heavily.

When you introduce a proper test framework (e.g. `pytest`), document the canonical commands here, such as:

- Run full test suite: `pytest`.
- Run a single test file: `pytest path/to/test_file.py -k test_name`.

## Guidance for future changes

- The `Controller/` package is the core of the system and is split into **streaming**, **vision primitives**, **semantic structuring**, and **LLM interaction**. When adding new features, prefer extending these layers rather than mixing concerns inside entry scripts.
- Treat `Controller/llava/` as vendored third-party code: avoid refactors there; instead, wrap it from higher-level modules in `Controller/`.
- The RAG side (`rag_app.py`) currently assumes segments are already written to disk. If you wire up `draft.py` + `VideoSplitter` into a more automated pipeline, keep their responsibilities clean: one process for **segment generation**, another for **indexing & serving**.
- Be mindful of GPU/CPU resource usage. YOLO, BLIP, CLIP, EasyOCR, and LLM calls are all heavy; for automated tests or CI, prefer lightweight smoke tests or mock layers over full end-to-end runs.
