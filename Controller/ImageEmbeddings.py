import cv2
import time
import torch
from transformers import CLIPProcessor, CLIPModel



class Vecorization:
    def __init__(self):
        self.clip_model = CLIPModel.from_pretrained("openai/clip-vit-large-patch14-336", torch_dtype=torch.float16, device_map="auto")
        self.clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-large-patch14-336")        

    @torch.inference_mode()
    def infer_images_batch(self, frames: list):
        """
        frames: list of np.array (H,W,3) in BGR or RGB
        return: list of detections per frame
        """
        results = self.clip_processor(images = frames, return_tensors="pt")["pixel_values"].to(self.clip_model.device, dtype=torch.float16)
        return results
    
    @torch.inference_mode()
    def infer_texts_batch(self, texts: list):
        """
        frames: list of str
        return: list of text embeddings
        """
        results = self.clip_processor(text = texts, return_tensors="pt", padding=True, truncation=True).to(self.clip_model.device)
        results = self.clip_model.get_text_features(**results)
        return results
    
if __name__=='__main__':
    
    cap = cv2.VideoCapture('./videos/Feline Interpretive Dance for Treats.mp4')
    clipper = Vecorization()
    
    batch = []
    while True:
        ret, frame = cap.read()
        if not ret:
            time.sleep(0.1)
            continue
        
        batch.append(frame)
        
        if len(batch) == 32:
            print("DONE", clipper.infer_batch(batch).shape)
            batch = []
        