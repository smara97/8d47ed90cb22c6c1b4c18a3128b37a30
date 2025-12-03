import base64
from typing import Optional

import cv2
import numpy as np

import base64
from typing import Optional

import cv2
import numpy as np


def encode_base64(frame: np.ndarray, image_format: str = "jpg") -> Optional[str]:
    """Encode a NumPy image frame to a base64 string.

    Args:
        frame: Image frame as a NumPy array in BGR or RGB format.
        image_format: Image format/extension for encoding (e.g. "jpg", "png").

    Returns:
        Base64-encoded string (without data URI prefix), or None if encoding fails.
    """
    if frame is None or not isinstance(frame, np.ndarray):
        return None

    # Ensure we have a 2D/3D array
    if frame.ndim not in (2, 3):
        return None

    ext = f".{image_format.lower()}"
    success, buffer = cv2.imencode(ext, frame)
    if not success:
        return None

    b64_bytes = base64.b64encode(buffer.tobytes())
    return b64_bytes.decode("utf-8")

def decode_frame_from_base64(frame_b64: str) -> Optional[np.ndarray]:
    """Decode a base64-encoded image into a NumPy BGR frame.

    Returns
    -------
    np.ndarray or None
        Decoded image as a HxWxC BGR array, or None if decoding fails.
    """
    if not frame_b64:
        return None

    try:
        img_bytes = base64.b64decode(frame_b64)
        img_array = np.frombuffer(img_bytes, dtype=np.uint8)
        frame = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
        return frame
    except Exception:
        return None
