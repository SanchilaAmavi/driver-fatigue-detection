from fastapi import APIRouter, Depends
from typing import List
from backend.app import auth
from backend.app.models.schemas import TripEvent, User

router = APIRouter()

TRIP_HISTORY = []

@router.post("/record")
def record_trip(event: TripEvent, current_user: User = Depends(auth.get_current_user)):
    TRIP_HISTORY.append(event.dict())
    return {"status": "success", "message": "Trip recorded", "trip_id": event.trip_id}

@router.get("/history", response_model=List[TripEvent])
def get_trip_history(current_user: User = Depends(auth.get_current_user)):
    return TRIP_HISTORY
