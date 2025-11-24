import os
import glob
from uuid import uuid4
import atexit
import chardet
import gradio as gr

from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

from sentence_transformers import SentenceTransformer
from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage



def safe_read(path):
    raw = open(path, "rb").read()
    enc = chardet.detect(raw)["encoding"] or "utf-8"
    return raw.decode(enc, errors="ignore")


class AnalyticsRagVideo:

    def __init__(
        self,
        segments_folder: str = "output/video_segments",
        qdrant_path: str = "./qdrant_video_db",
        model_name: str = "sentence-transformers/all-MiniLM-L6-v2",
        base_url="http://18.130.9.168/qwen_72b",
        api_key="na",
        llm_model="Qwen/Qwen3-32B",
    ):
        self.segments_folder = segments_folder

        self.embedder = SentenceTransformer(model_name)

        self.qdrant = QdrantClient(path=qdrant_path)

        if not self.qdrant.collection_exists("video_segments"):
            self.qdrant.create_collection(
                collection_name="video_segments",
                vectors_config=VectorParams(
                    size=384,
                    distance=Distance.COSINE
                )
            )

        self.llm = ChatOpenAI(
            base_url=base_url,
            api_key=api_key,
            model=llm_model,
            streaming=False,
            max_tokens=2048,
            temperature=0.0,
            timeout=90,
            extra_body={"chat_template_kwargs": {"enable_thinking": False}}
        )

        print("[Init] Video-RAG System Ready.")

        atexit.register(self._shutdown)

    def _shutdown(self):
        try:
            self.qdrant.close()
        except:
            pass


    def ingest_segments(self):
        txt_files = sorted(glob.glob(os.path.join(self.segments_folder, "segment-*.txt")))

        payloads, vectors, ids = [], [], []

        for txt_path in txt_files:

            # Safe, auto-detected encoding
            text = safe_read(txt_path).strip()

            seg_name = os.path.basename(txt_path).replace(".txt", "")
            video_path = os.path.join(self.segments_folder, seg_name + ".mp4")

            embedding = self.embedder.encode(text).tolist()

            payloads.append({
                "segment_name": seg_name,
                "text": text,
                "video_path": video_path,
            })
            vectors.append(embedding)
            ids.append(str(uuid4()))

        # Correct Qdrant API → build PointStruct list
        points = [
            PointStruct(
                id=ids[i],
                vector=vectors[i],
                payload=payloads[i]
            )
            for i in range(len(ids))
        ]

        # Upsert into DB
        self.qdrant.upsert(
            collection_name="video_segments",
            points=points
        )

        print(f"[Ingest] {len(txt_files)} segments inserted into Qdrant.")
        return f"Indexed {len(txt_files)} segments."


    def retrieve(self, query: str, top_k: int = 3):
        vector = self.embedder.encode(query).tolist()

        results = self.qdrant.search(
            collection_name="video_segments",
            query_vector=vector,
            limit=top_k
        )

        return [
            {
                "text": r.payload["text"],
                "video_path": r.payload["video_path"],
                "score": r.score
            }
            for r in results
        ]

    def rag_answer(self, question: str):
        segs = self.retrieve(question, top_k=3)

        context = "\n\n".join(
            f"[Segment]\n{seg['text']}\n(Video: {seg['video_path']})"
            for seg in segs
        )

        system = """
You are a Video-RAG analytic system.
Answer using ONLY the context below.
After the answer, list the source video paths.

Format:
Answer:
...
Sources:
- path
"""

        human = f"User question: {question}\n\nContext:\n{context}"

        response = self.llm.invoke([
            SystemMessage(content=system),
            HumanMessage(content=human)
        ])

        answer = getattr(response, "content", "")
        video_paths = [seg["video_path"] for seg in segs]

        return answer, video_paths, segs

    def build_gradio(self):

        def run_rag(query):
            answer, video_paths, raw_segments = self.rag_answer(query)

            videos_html = ""
            for vp in video_paths:
                if os.path.exists(vp):
                    videos_html += f"""
                    <div style='margin-top:10px'>
                        <video width="450" controls>
                            <source src="{vp}" type="video/mp4">
                        </video>
                        <p><b>{vp}</b></p>
                    </div>
                    """

            raw_texts = "\n\n---\n\n".join(
                f"Score: {seg['score']}\nVideo: {seg['video_path']}\nText:\n{seg['text']}"
                for seg in raw_segments
            )

            return answer, videos_html, raw_texts

        with gr.Blocks(css="body {background:#111; color:white;}") as ui:
            gr.Markdown("## 🎥 Analytics Video-RAG System")

            with gr.Row():
                query_input = gr.Textbox(
                    label="Ask a question about the video",
                    placeholder="Example: What happened when the car entered the parking?"
                )
                submit_btn = gr.Button("Analyze", variant="primary")

            answer_output = gr.Textbox(label="RAG Answer")
            video_output = gr.HTML(label="Relevant Video Segments")
            raw_output = gr.Textbox(label="Raw Retrieved Segments", lines=20)

            submit_btn.click(run_rag,
                             inputs=query_input,
                             outputs=[answer_output, video_output, raw_output])

        return ui


    def launch(self):
        ui = self.build_gradio()
        ui.launch(server_name="0.0.0.0", server_port=7860)


if __name__ == "__main__":
    rag = AnalyticsRagVideo()
    rag.ingest_segments()
    rag.launch()
