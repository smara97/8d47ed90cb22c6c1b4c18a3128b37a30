import torch
from transformers import BlipProcessor, BlipForConditionalGeneration
from Core.common.frame_utils import decode_frame_from_base64

class ImageCaption:
    def __init__(self):
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        
        self.processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-large")
        self.model = BlipForConditionalGeneration.from_pretrained("Salesforce/blip-image-captioning-large").to(self.device)
    
    
    @torch.inference_mode()
    def infer_batch(self, frame_msg):
        frame = frame_msg.get('frame')
        frame = decode_frame_from_base64(frame)        
        inputs = self.processor(frame, return_tensors="pt").to("cuda")        
        outputs = self.model.generate(**inputs)
        
        texts = [self.processor.decode(output, skip_special_tokens=True) for output in outputs]
        return texts