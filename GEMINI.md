# GEMINI.md - AI Pickleball Form Coach Project Context & Handover

Welcome! This document provides a complete overview of the codebase state, architecture, setup instructions, and recent technical decisions so any AI agent or developer can seamlessly pick up development on another machine.

---

## 1. Project Overview & Pivot

- **Product**: AI Pickleball Form Coach
- **Pivot History**: Originally built as an AI Basketball Coach in React Native (`mobile-app/` - deleted). Pivoted to an **AI Pickleball Form Coach** with a brand-new **Flutter (Dart)** frontend (`pickleball_app/`) and **FastAPI** backend (`backend/`).
- **Legacy Preservation**: The `prototype/` directory has been intentionally preserved for reference and should not be deleted.
- **Commercial Roadmap**: See [COMMERCIAL_ROADMAP.md](COMMERCIAL_ROADMAP.md) for Phase 1–3 infrastructure, cost projections (Cloudflare R2 + GCP Cloud Run), and App Store compliance plans.

---

## 2. Architecture & File Structure

```text
ai-coach/
├── COMMERCIAL_ROADMAP.md   # Scaling & production roadmap (Phase 1-3)
├── GEMINI.md               # Handover document & system context (this file)
├── README.md               # Quick project summary
├── backend/                # Python FastAPI Backend (Phase 1 Local Dev)
│   ├── app.db              # SQLite database (SQLAlchemy)
│   ├── auth.py             # Native JWT auth + direct bcrypt hashing + Dev bypass
│   ├── database.py         # SQLAlchemy engine, SessionLocal, User & Analysis models
│   ├── main.py             # FastAPI entrypoint, pose extraction & Gemini integration
│   ├── requirements.txt    # Backend dependencies
│   ├── uploads/            # Local video uploads folder (served statically)
│   └── venv/               # Python virtual environment
├── pickleball_app/         # Flutter Mobile / Web Frontend
│   ├── pubspec.yaml        # Flutter package dependencies
│   └── lib/
│       ├── main.dart       # App entrypoint (MaterialApp router)
│       ├── data/
│       │   ├── models/     # StrokeAnalysis, TrackingFrame models
│       │   └── services/   # AuthService (Dev Auto-Login), ApiService (Multipart upload)
│       └── ui/
│           ├── features/auth/      # LoginView (Dev login option)
│           ├── features/home/      # HomeView (Upload video, pick file)
│           └── features/results/   # ResultsView (9:16 Video player + PosePainter canvas)
└── prototype/              # Legacy Web prototype (kept for reference)
```

---

## 3. Quick Start Guide (New PC Setup)

### Prerequisites
- Python 3.10+
- Flutter SDK (3.x+) & Dart
- OpenCV / C++ build dependencies (standard for MediaPipe)

### Backend Setup (FastAPI)
```powershell
cd backend

# Create virtual environment if missing
python -m venv venv
.\venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set Gemini API Key (replace with valid key)
$env:GEMINI_API_KEY="YOUR_GEMINI_API_KEY"

# Launch FastAPI server on port 8000
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Setup (Flutter)
```powershell
cd pickleball_app

# Fetch packages
flutter pub get

# Launch Flutter Web server on port 8080
flutter run -d web-server --web-port 8080 --web-hostname localhost
```

---

## 4. Current State & Dev Bypass Features

- **Backend API**: `http://localhost:8000`
  - Auth endpoints: `/auth/register`, `/auth/login`
  - Upload endpoint: `/upload-video` (returns biomechanical joint angles + Gemini breakdown)
  - Static file serving: `/uploads/{filename}`
- **Dev Auto-Login**: Active in `pickleball_app/lib/data/services/auth_service.dart`. On startup, if no token exists, it auto-authenticates with `dev_user_123` / `dev_token` so UI testing never blocks on credentials.
- **Vertical Video Optimization**: `ResultsView` constrains video height (`MediaQuery.of(context).size.height * 0.45`) to gracefully handle vertical 9:16 mobile videos without `Column` overflow errors.
- **Interactive Timeline Seeking**: Tapping any stroke card in `ResultsView` automatically parses the timestamp (`MM:SS.s`) and seeks the video player directly to that shot timestamp (`_seekToStroke`), highlighting the selected card with an active border.
- **History View & Session Persistence**: Past coaching runs are saved to SQLite (`app.db`) and accessible via `GET /analyses`. Users can view past sessions on the new `HistoryView` screen (`pickleball_app/lib/ui/features/history/history_view.dart`) and replay any past analysis with one tap.
- **Mobile UI/UX Shell & Profile Dashboard**: Material 3 `NavigationBar` shell ([main_shell.dart](file:///c:/Users/user/Documents/ai-coach/pickleball_app/lib/ui/shell/main_shell.dart)) hosting 3 tabs (**Coach**, **History**, **Profile**), custom Teal court palette, and a performance stats dashboard ([profile_view.dart](file:///c:/Users/user/Documents/ai-coach/pickleball_app/lib/ui/features/profile/profile_view.dart)).
- **Video Preview & Multi-Stage Analysis Progress**: On [home_view.dart](file:///c:/Users/user/Documents/ai-coach/pickleball_app/lib/ui/features/home/home_view.dart), selecting a clip instantiates an inline video preview with metadata (filename, file size in MB), and clicking analyze triggers a step-by-step 3-stage progress card (*Stage 1: Uploading, Stage 2: Pose Tracking, Stage 3: Gemini AI Analysis*).
- **Dockerized Container Backend**: Python FastAPI backend has been containerized with OpenCV & MediaPipe system dependencies ([backend/Dockerfile](file:///c:/Users/user/Documents/ai-coach/backend/Dockerfile)) and tested running in Docker (`pickleball-backend-container` listening on `http://localhost:8000`). Ready for Phase 2 GCP Cloud Run / Render deployment.
- **Railway Cloud Deployment (Phase 2)**: Linked project `pickleball-backend` on Railway (Southeast Asia) with managed PostgreSQL database (`postgres-volume`). 
- **Production Backend URL**: `https://pickleball-backend-production-c00e.up.railway.app`
- **Production Web App URL (Railway Unified)**: [https://pickleball-backend-production-c00e.up.railway.app/ui](https://pickleball-backend-production-c00e.up.railway.app/ui)
- **Production Web App URL (Vercel Static)**: [https://temporary-racing-monsoon-v3qounh.vercel.app](https://temporary-racing-monsoon-v3qounh.vercel.app)
- **Root Dockerfile & Railway Auto-Deploy**: Created root `Dockerfile` and `railway.json` mapping `backend/` files so pushing to `origin main` automatically builds and deploys to Railway cleanly.
- **Frontend API Config**: Created `ApiConfig` in [api_config.dart](file:///c:/Users/user/Documents/ai-coach/pickleball_app/lib/data/services/api_config.dart) defaulting to Railway Production API, with `--dart-define=API_URL=...` override for local dev testing.
- **Mandatory User Authentication Enforced**: Removed Dev Auto-Login bypass in `auth_service.dart`. Web UI and mobile clients now require real email/password registration and login (`/auth/register` & `/auth/login`) with JWT token persistence.
- **Cloudflare R2 Object Storage**: Integrated `storage.py` using `boto3` in `process_video`. Automatically uploads video clips to Cloudflare R2 when `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME`, and `R2_ACCOUNT_ID` / `R2_PUBLIC_DOMAIN` environment variables are set, with seamless fallback to static file storage when unconfigured.
- **Robust Gemini Fallback**: Wrapped Gemini API calls in `main.py` with try/except fallback (`get_fallback_analysis`) to guarantee uninterrupted pose tracking analysis even if Gemini API rates or prepayments are temporarily exhausted.
- **End-to-End Test Verified**: Video uploads process through MediaPipe pose tracking, store relative URLs (`/uploads/dev_user_123/...`), and persist structured coaching records into Railway PostgreSQL database (`GET /analyses` verified returning HTTP 200).

---

## 5. Past Technical Gotchas & Critical Guidelines

1. **Direct `bcrypt` Password Hashing**:
   - `passlib 1.7.4` has a known bug with `bcrypt > 5.0` (`ValueError: password cannot be longer than 72 bytes`).
   - **Do NOT use passlib's CryptContext**. Use direct `bcrypt` methods in `auth.py`: `bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()` and `bcrypt.checkpw()`.

2. **Flutter Web File Uploads**:
   - `http.MultipartFile.fromPath()` crashes on Flutter Web due to missing `dart:io`.
   - Always use `XFile.readAsBytes()` and `http.MultipartFile.fromBytes(bytes, filename: ...)` in `api_service.dart`.

3. **Gemini Model Versioning**:
   - `gemini-2.0-flash-exp` returns 404 NOT_FOUND.
   - `main.py` uses `gemini-3.6-flash` with a fallback chain (`gemini-3.6-flash` $\rightarrow$ `gemini-2.5-flash` $\rightarrow$ `gemini-1.5-flash`).

4. **Background Task Cancellation Pop-ups**:
   - When restarting `flutter run` or `uvicorn` using command tools, the system emits `Task ... was canceled`. This is a normal lifecycle event when stopping older server instances, not a user abort.

---

## 6. Next Steps for Next Session

1. Test video analysis with mobile 9:16 pickleball serve/dink videos.
2. Verify joint angle overlay (`PosePainter`) syncs accurately with video playback timeline.
3. Reference `COMMERCIAL_ROADMAP.md` when preparing for Phase 2 Cloud migration (Cloudflare R2 + GCP Cloud Run + Supabase Auth).
