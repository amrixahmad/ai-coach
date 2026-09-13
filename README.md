# AI Pickleball Coach

A mobile & web application that analyzes pickleball stroke mechanics (dinks, serves, drops, drives) using Gemini 2.0 Flash AI and MediaPipe pose joint-angle tracking.

---

## 📁 Repository Structure

- `pickleball_app/`: Flutter mobile & web application (MVVM architecture, `CustomPainter` biomechanics overlays).
- `backend/`: FastAPI Python analysis engine (Native JWT Auth, SQLite DB, MediaPipe 2D joint angle calculator).
- `prototype/`: Original Python proof-of-concept (`ball.py` & `ball.json`).
- `COMMERCIAL_ROADMAP.md`: Infrastructure, cost scaling, and deployment guide for commercial launch.

---

## ⚡ Quick Start Instructions

### 1. Backend Setup (FastAPI + SQLite + JWT)

The backend handles video processing, calling Gemini 2.0 Flash, MediaPipe joint-angle calculation, and native JWT authentication.

1. Navigate to backend:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Configure Environment Variables (create `.env` in `backend/`):
   ```env
   GEMINI_API_KEY=your_gemini_key
   JWT_SECRET=your_custom_jwt_secret
   ```
4. Run the backend server:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

---

### 2. Mobile App Setup (Flutter)

1. Navigate to `pickleball_app/`:
   ```bash
   cd pickleball_app
   ```
2. Install package dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app in Chrome Web Preview:
   ```bash
   flutter run -d chrome
   ```
   *(Or test on an Android emulator or iOS simulator via `flutter run`)*.

---

## 🧠 Workflow Pipeline

1. **Authentication**: User registers/logs in via native JWT endpoints (`/auth/register`, `/auth/login`).
2. **Video Input**: User picks a stroke or rally clip from gallery.
3. **Analysis Engine**:
   - Flutter app streams video to `POST /process-video` with Bearer auth token.
   - FastAPI verifies JWT user token.
   - MediaPipe computes frame-by-frame 2D joint angles (elbow, knee, shoulder).
   - Gemini 2.0 Flash analyzes stroke form, wrist stability, and court positioning.
   - Analysis record is saved locally in SQLite (`app.db`) and video binary is stored under `backend/uploads/`.
4. **Interactive Feedback**: Flutter app renders video playback with real-time `CustomPainter` pose indicators and stroke feedback cards.
