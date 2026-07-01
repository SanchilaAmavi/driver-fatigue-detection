<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=6,11,20&height=200&section=header&text=NexDrive&fontSize=68&fontColor=ffffff&animation=fadeIn&fontAlignY=38" width="100%" alt="NexDrive banner"/>

### AI-Powered Driver Fatigue & Safety Detection Platform

<a href="https://sanchila-amavi.vercel.app/">
  <img src="https://readme-typing-svg.demolab.com/?lines=Real-Time+Driver+Drowsiness+Detection;EfficientNet-B0+%7C+93.24%25+Accuracy;PERCLOS+%2B+Computer+Vision+%2B+Voice+AI;PyTorch+%C2%B7+FastAPI+%C2%B7+Flutter&font=Fira+Code&center=true&width=650&height=45&duration=3000&pause=1000&color=0891B2&vCenter=true&size=22" alt="Typing SVG" />
</a>

<br/>

[![Python](https://img.shields.io/badge/Python-3.11%2B-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![PyTorch](https://img.shields.io/badge/PyTorch-EfficientNet--B0-EE4C2C?style=for-the-badge&logo=pytorch&logoColor=white)](https://pytorch.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Flutter](https://img.shields.io/badge/Flutter-Mobile-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge)](LICENSE)

<br/>

[![Stars](https://img.shields.io/github/stars/SanchilaAmavi/driver-fatigue-detection?style=social)](https://github.com/SanchilaAmavi/driver-fatigue-detection/stargazers)
[![Forks](https://img.shields.io/github/forks/SanchilaAmavi/driver-fatigue-detection?style=social)](https://github.com/SanchilaAmavi/driver-fatigue-detection/network/members)
[![Issues](https://img.shields.io/github/issues/SanchilaAmavi/driver-fatigue-detection?color=7c3aed)](https://github.com/SanchilaAmavi/driver-fatigue-detection/issues)
[![Maintained](https://img.shields.io/badge/Maintained-Yes-0891b2?style=flat-square)](https://github.com/SanchilaAmavi/driver-fatigue-detection/commits/main)

<p>
  <a href="#-overview">Overview</a> •
  <a href="#-features">Features</a> •
  <a href="#-architecture">Architecture</a> •
  <a href="#-tech-stack">Tech Stack</a> •
  <a href="#-getting-started">Getting Started</a> •
  <a href="#-api-reference">API</a> •
  <a href="#-project-structure">Structure</a> •
  <a href="#-roadmap">Roadmap</a> •
  <a href="#-author">Author</a>
</p>

</div>

<br/>

## 📌 Overview

**NexDrive** is a full-stack, software-first driver safety platform that detects fatigue and drowsiness in real time using deep learning and computer vision. It fuses a fine-tuned **EfficientNet-B0** classifier (**93.24% validation accuracy**), **PERCLOS-based eye-closure scoring**, and real-time facial landmark tracking with a **FastAPI** inference backend and a cross-platform **Flutter** mobile app - complete with voice alerts, an AI voice assistant, emergency SOS, and live GPS trip tracking.

Built to bridge the gap between an offline research model and a production-ready, deployable safety application.

<div align="center">

> 🎬 **Demo GIF / screen recording coming soon** - record a screen capture of the app (e.g. with [ScreenToGif](https://www.screentogif.com/) or `flutter screenshot`), save it as `docs/demo.gif`, then replace this block with:
> `<img src="docs/demo.gif" width="70%" alt="NexDrive demo"/>`

</div>

<br/>

## ✨ Features

<table>
<tr>
<td width="50%" valign="top">

### 🧠 AI / Detection Engine
- **EfficientNet-B0** transfer-learning model, 4-class classifier (open eye / closed eye / yawn / no yawn)
- **93.24%** validation accuracy on CEW + Yawn datasets
- **PERCLOS** (Percentage of Eyelid Closure) fatigue scoring engine
- Real-time face & landmark tracking via OpenCV
- 4-tier severity alert system (Normal → Mild → Moderate → Critical)
- CLAHE preprocessing + Albumentations augmentation pipeline

</td>
<td width="50%" valign="top">

### 📱 Mobile & Platform
- Cross-platform **Flutter** app (Android-ready)
- Bidirectional **AI voice assistant** with wakeword detection
- Siri-style animated voice overlay & conversational memory
- Real-time voice alerts for drowsiness events
- **Emergency SOS** with live location sharing
- **GPS trip tracking** with map visualization

</td>
</tr>
<tr>
<td width="50%" valign="top">

### ⚙️ Backend / API
- **FastAPI** REST backend with JWT authentication
- `/predict/image` real-time inference endpoint
- Trip history logging via **SQLAlchemy**
- WSO2-friendly API structure for enterprise gateways
- Dockerized deployment (`docker compose up`)

</td>
<td width="50%" valign="top">

### 📊 Data & Analytics
- Trip-level fatigue analytics & history
- Session-based severity logs
- Interactive API docs via Swagger (`/docs`)
- Structured SQLite / production-ready DB layer

</td>
</tr>
</table>

<br/>

## 🏗️ Architecture

```mermaid
flowchart LR
    A["📷 Camera Feed<br/>(Flutter App)"] --> B["Face & Eye<br/>Landmark Tracking"]
    B --> C["EfficientNet-B0<br/>Classifier"]
    C --> D["PERCLOS<br/>Fatigue Engine"]
    D --> E{Severity Level}
    E -->|Normal| F["✅ Continue Monitoring"]
    E -->|Mild / Moderate| G["🔊 Voice Alert<br/>AI Assistant"]
    E -->|Critical| H["🚨 Emergency SOS<br/>+ GPS Location"]
    B -.image.-> I["FastAPI Backend<br/>/predict/image"]
    I --> J[("SQLAlchemy DB<br/>Trip History")]
    I --> K["JWT Auth<br/>/auth/token"]

    style A fill:#0891b2,color:#fff
    style C fill:#7c3aed,color:#fff
    style D fill:#7c3aed,color:#fff
    style H fill:#ef4444,color:#fff
    style I fill:#22c55e,color:#fff
```

<br/>

## 🛠️ Tech Stack

<div align="center">

![Python](https://skillicons.dev/icons?i=py)
![PyTorch](https://skillicons.dev/icons?i=pytorch)
![FastAPI](https://skillicons.dev/icons?i=fastapi)
![Flutter](https://skillicons.dev/icons?i=flutter)
![Dart](https://skillicons.dev/icons?i=dart)
![OpenCV](https://skillicons.dev/icons?i=opencv)
![SQLite](https://skillicons.dev/icons?i=sqlite)
![Docker](https://skillicons.dev/icons?i=docker)
![Git](https://skillicons.dev/icons?i=git)
![VSCode](https://skillicons.dev/icons?i=vscode)

</div>

| Layer | Technologies |
|---|---|
| **Deep Learning** | PyTorch, EfficientNet-B0, Transfer Learning, Albumentations |
| **Computer Vision** | OpenCV, CLAHE preprocessing, Landmark tracking, PERCLOS scoring |
| **Backend** | FastAPI, SQLAlchemy, JWT Auth, Uvicorn |
| **Mobile** | Flutter, Dart, Voice Assistant (Claude API integration) |
| **DevOps** | Docker, Docker Compose |
| **Data** | CEW Dataset, Yawn Dataset, SQLite |

<br/>

## 🚀 Getting Started

### Prerequisites
- Python **3.11 or 3.12** recommended
- Flutter SDK (for the mobile app)
- Docker *(optional, for containerized deployment)*

### 1️⃣ Clone the repository
```bash
git clone https://github.com/SanchilaAmavi/driver-fatigue-detection.git
cd driver-fatigue-detection
```

### 2️⃣ Backend setup
```bash
# Create virtual environment
python -m venv venv
venv\Scripts\activate        # Windows
source venv/bin/activate     # macOS / Linux

# Install core dependencies
pip install -r requirements.txt

# Install ML dependencies (required for /predict/image)
pip install -r requirements-ml.txt

# Run the API server
uvicorn backend.app.main:app --reload
```

Open the interactive API docs at **http://127.0.0.1:8000/docs**

### 3️⃣ Run with Docker
```bash
docker compose up --build
```

### 4️⃣ Mobile app
```bash
cd mobile/flutter
flutter pub get
flutter run
```

<br/>

## 📡 API Reference

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Health check |
| `POST` | `/auth/token` | Request JWT access token |
| `GET` | `/auth/users/me` | Fetch current authenticated user profile |
| `POST` | `/predict/image` | Upload image → real-time fatigue prediction |
| `POST` | `/trips/record` | Record a completed trip's results |
| `GET` | `/trips/history` | Retrieve trip history for the current user |

<br/>

## 📁 Project Structure

```
driver-fatigue-detection/
├── backend/                 # FastAPI backend service
│   └── app/
│       ├── api/              # Route handlers
│       ├── config.py         # App configuration
│       ├── models/            # SQLAlchemy models
│       ├── services/          # ML inference & business logic
│       └── main.py           # App entry point
├── mobile/
│   └── flutter/               # Flutter mobile application
├── src/                       # Model training / experimentation
├── docs/                      # Documentation
├── tests/                     # Test automation
├── requirements.txt            # Core backend dependencies
├── requirements-ml.txt         # PyTorch / ML dependencies
├── docker-compose.yml
├── Dockerfile
└── README.md
```

<br/>

## 🗺️ Roadmap

- [x] EfficientNet-B0 fatigue classifier (93.24% accuracy)
- [x] PERCLOS-based severity scoring engine
- [x] FastAPI inference backend with JWT auth
- [x] Flutter mobile app with voice assistant
- [x] Emergency SOS + GPS trip tracking
- [x] Dockerized deployment
- [ ] WSO2 API Manager gateway integration
- [ ] WSO2 Identity Server authentication
- [ ] Expanded test automation suite
- [ ] Cloud deployment & CI/CD pipeline
- [ ] On-device (edge) inference optimization

<br/>

## 🎯 Skill Confidence

<div align="center">

**Deep Learning / PyTorch**
![](https://progress-bar.dev/93/?title=EfficientNet-B0&width=400&color=0891b2)

**Computer Vision / OpenCV**
![](https://progress-bar.dev/90/?title=PERCLOS+%2F+Landmarks&width=400&color=7c3aed)

**Backend / FastAPI**
![](https://progress-bar.dev/88/?title=REST+%2B+JWT&width=400&color=22c55e)

**Mobile / Flutter**
![](https://progress-bar.dev/92/?title=Cross-Platform+App&width=400&color=0891b2)

</div>

<br/>

## 🧪 Model Performance

| Metric | Score |
|---|---|
| **Validation Accuracy** | 93.24% |
| **Classes** | Open Eye · Closed Eye · Yawn · No Yawn |
| **Datasets** | CEW, Yawn Dataset |
| **Architecture** | EfficientNet-B0 (Transfer Learning) |
| **Preprocessing** | CLAHE + Albumentations Augmentation |

<br/>

<div align="center">


<br/>

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:22c55e,50:7c3aed,100:0891b2&height=120&section=footer" width="100%"/>

**⭐ If this project helped you, consider giving it a star!**

</div>
