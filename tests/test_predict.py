import io
from fastapi.testclient import TestClient
from backend.app.main import app

client = TestClient(app)


def get_auth_token():
    response = client.post(
        "/auth/token",
        data={"username": "driver@example.com", "password": "driverpass"},
    )
    assert response.status_code == 200
    return response.json()["access_token"]


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_predict_invalid_file():
    token = get_auth_token()
    response = client.post(
        "/predict/image",
        headers={"Authorization": f"Bearer {token}"},
        files={"image": ("test.txt", b"notanimage", "text/plain")},
    )
    assert response.status_code == 400


def test_trips_history_requires_auth():
    response = client.get("/trips/history")
    assert response.status_code == 401
