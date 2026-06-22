from pydantic import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Driver Fatigue Detection API"
    model_path: str = "models/best_model.pth"
    database_url: str = "sqlite:///./backend.db"
    allowed_hosts: list[str] = ["*"]
    secret_key: str = "CHANGE_ME_TO_A_SECURE_RANDOM_STRING"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    class Config:
        env_file = ".env"

settings = Settings()
