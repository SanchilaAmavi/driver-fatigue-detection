<<<<<<< HEAD
# Driver Fatigue Detection System

> Professional software-first driver safety application with mobile and API support.

## Overview

This repository contains a complete software architecture for driver fatigue detection, including:

- `FastAPI` backend for ML inference
- `PyTorch` model service
- `WSO2`-friendly API structure
- `React Native` mobile app scaffold
- `SQLAlchemy` database model for trip history
- production-style repository structure

## Project structure

```
driver-fatigue-detection/
├── backend/              # FastAPI backend service
│   ├── app/
│   │   ├── api/
│   │   ├── config.py
│   │   ├── models/
│   │   ├── services/
│   │   └── main.py
│   └── backend.db        # SQLite database (generated at runtime)
├── mobile/               # React Native mobile app scaffold
├── notebooks/            # Notebooks and experiment history
├── reports/              # Evaluation graphs and dashboard results
├── models/               # Trained model weights (not committed)
├── requirements.txt
├── README.md
└── .gitignore
```

## Backend API

### Endpoints

- `GET /health` — health check
- `POST /auth/token` — JWT token request
- `GET /auth/users/me` — fetch current user profile
- `POST /predict/image` — image upload and fatigue prediction
- `POST /trips/record` — record trip results
- `GET /trips/history` — retrieve trip records

## How to run

1. Create a virtual environment:

```bash
python -m venv venv
venv\Scripts\activate
```

2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Start the backend:

```bash
uvicorn backend.app.main:app --reload
```

4. Open API docs:

```
http://127.0.0.1:8000/docs
```

5. Run with Docker:

```bash
docker compose up --build
```

### Optional ML dependencies

The backend inference service uses PyTorch for model loading. Install the correct ML dependencies for your platform before using `POST /predict/image`.

```bash
pip install -r requirements-ml.txt
```

> Recommended Python version: 3.11 or 3.12. Some packages may not yet provide wheels for Python 3.15.

## Mobile apps

- Flutter starter app: `mobile/flutter/`
- React Native starter app: `mobile/react_native/`

## Next steps

- Add `React Native` mobile UI in `mobile/`
- Add WSO2 API Manager gateway configuration
- Add user authentication with WSO2 Identity Server
- Add test automation in `tests/`
- Add deployment configuration in `docs/`
=======
# driver-fatigue-detection
Real-time driver drowsiness detection using EfficientNet-B0 | Computer Vision | PyTorch
>>>>>>> 4dfdf83c91c4e96cc26f2f58f3eda4dcc1c20eb9
