import io
import json
import torch
import fitz
from PIL import Image
from surya.prediction import OCRRecognitionPredictor, OCRDetectionPredictor
from surya.model.recognition.model import load_model as load_rec_model
from surya.model.recognition.processor import load_processor as load_rec_processor
from surya.model.detection.model import load_model as load_det_model
from surya.model.detection.processor import load_processor as load_det_processor

BATCH_SIZE = 4 

def model_fn(model_dir):
    """Initialise les modèles une seule fois au démarrage."""
    device = "cuda" if torch.cuda.is_available() else "cpu"
    
    # Chargement des composants
    det_model = load_det_model()
    det_processor = load_det_processor()
    rec_model = load_rec_model()
    rec_processor = load_rec_processor()
    
    # Initialisation des Predictors officiels (API v0.4+)
    det_predictor = OCRDetectionPredictor()
    rec_predictor = OCRRecognitionPredictor()
    
    return {
        "det_predictor": det_predictor, 
        "rec_predictor": rec_predictor,
        "langs": ["en"] # Langue par défaut
    }

def input_fn(request_body, request_content_type):
    if request_content_type == 'application/pdf':
        return fitz.open(stream=request_body, filetype="pdf")
    raise ValueError(f"Type {request_content_type} non supporté.")

def predict_fn(pdf_doc, context):
    det_predictor = context["det_predictor"]
    rec_predictor = context["rec_predictor"]
    langs = context["langs"]
    
    all_ocr_results = []
    num_pages = len(pdf_doc)

    # Traitement du PDF par petits groupes de pages (Batching)
    for i in range(0, num_pages, BATCH_SIZE):
        batch_images = []
        upper_bound = min(i + BATCH_SIZE, num_pages)
        
        for page_num in range(i, upper_bound):
            page = pdf_doc.load_page(page_num)
            # Matrix(2,2) = 144 DPI (bon compromis vitesse/précision)
            pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
            img = Image.open(io.BytesIO(pix.tobytes())).convert("RGB")
            batch_images.append(img)
        
        # 1. Détection (sur le batch actuel)
        predictions = det_predictor(batch_images)
        
        # 2. Reconnaissance (sur le batch actuel)
        batch_results = rec_predictor(batch_images, [langs] * len(batch_images), predictions)
        
        # 3. Formatage et stockage
        for idx, res in enumerate(batch_results):
            all_ocr_results.append({
                "page": i + idx,
                "text_lines": [line.model_dump() for line in res.text_lines]
            })
            
        # Optionnel: Libérer la mémoire cache GPU après chaque batch
        if torch.cuda.is_available():
            torch.cuda.empty_cache()

    return all_ocr_results

def output_fn(prediction, accept):
    return json.dumps(prediction), 'application/json'
