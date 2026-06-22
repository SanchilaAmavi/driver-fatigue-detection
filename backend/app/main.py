from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.app.api.auth import router as auth_router
from backend.app.api.predict import router as predict_router
from backend.app.api.trips import router as trips_router
from backend.app.db.session import engine
from backend.app.db.models import Base

app = FastAPI(
    title="Driver Fatigue Detection API",
    description="FastAPI backend for driver drowsiness detection with mobile app integration.",
    version="0.1.0",
)


@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(predict_router, prefix="/predict", tags=["predict"])
app.include_router(trips_router, prefix="/trips", tags=["trips"])

@app.get("/health")
def health_check():
    return {"status": "ok", "message": "Driver fatigue API is running"}
