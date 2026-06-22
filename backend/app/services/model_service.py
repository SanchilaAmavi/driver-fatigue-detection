import io
from typing import Dict
from PIL import Image
from backend.app.models.model import FatigueModel

MODEL_PATH = "models/best_model.pth"
CLASSES = ["yawn", "no_yawn", "closed", "open"]

model = None
transform = None
DEVICE = None


def _initialize_model_environment():
    global transform, DEVICE
    try:
        import torch
        import torchvision.transforms as transforms
    except ImportError:
        raise RuntimeError("PyTorch and torchvision are required for model inference.")

    DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    transform = transforms.Compose([
        transforms.Resize((64, 64)),
        transforms.Grayscale(num_output_channels=3),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
    ])


def load_model() -> FatigueModel:
    global model, DEVICE, transform
    if model is None:
        _initialize_model_environment()
        import torch

        model = FatigueModel(num_classes=len(CLASSES), dropout=0.5)
        model.load_state_dict(torch.load(MODEL_PATH, map_location=DEVICE))
        model.to(DEVICE)
        model.eval()
    return model


def predict_image(image_bytes: bytes) -> Dict:
    model = load_model()
    import torch
    import torch.nn.functional as F

    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    tensor = transform(image).unsqueeze(0).to(DEVICE)
    with torch.no_grad():
        outputs = model(tensor)
        probabilities = F.softmax(outputs, dim=1)[0].cpu().tolist()
    best_index = int(torch.argmax(outputs, dim=1).item())
    return {
        "label": CLASSES[best_index],
        "score": probabilities[best_index],
        "probabilities": {CLASSES[i]: float(probabilities[i]) for i in range(len(CLASSES))},
    }
