import numpy as np
from typing import Any, Optional

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage


class LLMClient:
    def __init__(
        self,
        base_url: str = "http://18.130.9.168/qwen_72b",
        api_key: str = "na",
        model: str = "Qwen/Qwen3-32B",
        temperature: float = 0.0,
        max_tokens: int = 4096,
        timeout: int = 90,
        streaming: bool = True,
    ):
        self.llm = ChatOpenAI(
            base_url=base_url,
            api_key=api_key,
            model=model,
            streaming=streaming,
            max_tokens=max_tokens,
            temperature=temperature,
            timeout=timeout,
            extra_body={"chat_template_kwargs": {"enable_thinking": False}}
        )

    def invoke(self, system: str, human: str) -> str:
        """Send a system + human prompt to the LLM and return text response only."""
        resp = self.llm.invoke([SystemMessage(content=system), HumanMessage(content=human)])
        return getattr(resp, "content", "") or str(resp)



class VideoSummarizer:
    """
    Frame-by-frame Video Summarization Agent.
    Produces dense, RAG-optimized summaries from detections, captions, OCR, and scene graphs.
    """

    def __init__(
        self,
        base_url: str = "http://18.130.9.168/qwen_72b",
        api_key: str = "na",
        model: str = "Qwen/Qwen3-32B",
        temperature: float = 0.0,
        max_tokens: int = 4096,
        timeout: int = 90,
        streaming: bool = True,
    ):

        self.client = LLMClient(
            base_url=base_url,
            api_key=api_key,
            model=model,
            temperature=temperature,
            max_tokens=max_tokens,
            timeout=timeout,
            streaming=streaming,
        )

        self.previous_summary: Optional[str] = None
        self.frame_count: int = 0

        self.system_prompt = (
            "You are a Video Narrative Agent. Your job is to convert frame-by-frame metadata "
            "into a natural flowing narrative that describes what is happening in the video. "
            "The narrative must sound like a human summarizing events they saw on screen. "
            "Do not mention any models, detections, OCR, boxes, captions, or technical processes. "
            "Never include raw data, numbers, coordinates, labels, or metadata fields. "
            "Do not begin with words like 'Frame' or reference the frame structure. "
            "Simply describe the scene, the people, objects, environment, interactions, and changes over time. "
            "Write in a smooth chronological style from the start of the video up to the current moment. "
            "Always produce a single paragraph of natural descriptive text. "
            "The text will be stored in RAG, so ensure it is dense, meaningful, and captures semantic events clearly."
        )

    def process_frame(self, frame_metadata: dict) -> str:
        self.frame_count += 1

        # Build human prompt
        if self.previous_summary:
            human_prompt = (
                f"Here is the earlier narrative summary of the video:\n"
                f"{self.previous_summary}\n\n"
                f"Here is new frame information:\n"
                f"{frame_metadata}\n\n"
                "Update the narrative to include the new moment in the video. "
                "Blend it naturally into the flowing story. "
                "Do not mention models, detections, OCR, bounding boxes, or metadata. "
                "Do not mention 'frames'. "
                "Describe only what is happening in the scene as if watching the video directly. "
                "Write one continuous paragraph."
            )
        else:
            human_prompt = (
                f"Video begins with the following frame information:\n"
                f"{frame_metadata}\n\n"
                "Describe what is happening in the video so far in natural narrative form. "
                "Do not mention models, detections, OCR, bounding boxes, or metadata fields. "
                "Do not mention 'frame'. "
                "Write one continuous paragraph."
            )

        summary = self.client.invoke(system=self.system_prompt, human=human_prompt)
        self.previous_summary = summary
        return summary


    def reset(self) -> None:
        """Reset the summary context."""
        self.previous_summary = None
        self.frame_count = 0

    def get_current_summary(self) -> Optional[str]:
        return self.previous_summary

    def get_frame_count(self) -> int:
        return self.frame_count