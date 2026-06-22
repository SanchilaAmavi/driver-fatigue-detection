from fastapi import APIRouter, File, UploadFile, HTTPException, Depends
from pydantic import BaseModel
from backend.app import auth
from backend.app.services.model_service import predict_image

router = APIRouter()

class PredictionResponse(BaseModel):
    label: str
    score: float
    probabilities: dict

@router.post("/image", response_model=PredictionResponse)
async def predict_image_endpoint(
    image: UploadFile = File(...),
    current_user: auth.User = Depends(auth.get_current_user),
):
    if image.content_type not in {"image/jpeg", "image/png"}:
        raise HTTPException(status_code=400, detail="Only JPEG and PNG images are supported.")

    image_bytes = await image.read()
    result = predict_image(image_bytes)
    return result
