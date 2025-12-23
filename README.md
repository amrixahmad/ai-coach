# AI Basketball Coach

A mobile app that analyzes your basketball shot using Gemini and MediaPipe.

## Structure
- `mobile-app/`: Expo (React Native) app.
- `backend/`: FastAPI Python server (Analysis Engine).
- `prototype/`: Original Python proof-of-concept.

## Setup Instructions

### 1. Backend Setup (Python)
The backend handles video processing, calling Gemini API, and running MediaPipe.

1. Navigate to backend: `cd backend`
2. Create virtual environment (optional but recommended):
   ```bash
   python -m venv venv
   # Windows
   .\venv\Scripts\activate
   # Mac/Linux
   source venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Set up Environment Variables:
   - Create a `.env` file in `backend/`
   - Add your Gemini API Key: `GEMINI_API_KEY=your_key_here`
   - (Get a key from [aistudio.google.com](https://aistudio.google.com/))

5. Run the server:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

### 2. Mobile App Setup (Expo)
The frontend allows recording/uploading videos and viewing results.

1. Navigate to app: `cd mobile-app`
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set up Environment Variables:
   - Rename/Create `.env`
   - Add Supabase keys (if using Auth later):
     ```
     EXPO_PUBLIC_SUPABASE_URL=your_url
     EXPO_PUBLIC_SUPABASE_ANON_KEY=your_key
     ```
4. **Important**: Update Backend URL
   - Open `app/index.tsx`
   - Update `BACKEND_URL` to your machine's IP address if testing on a real device.
   - Use `http://10.0.2.2:8000` for Android Emulator.
   - Use `http://localhost:8000` for iOS Simulator.

5. Run the app:
   ```bash
   npm run ios
   # or
   npm run android
   ```

## Workflow
1. User picks a video in the App.
2. App uploads video to `http://<backend>/process-video`.
3. Backend uploads to Gemini for semantic analysis + runs MediaPipe for head tracking.
4. Backend returns JSON.
5. App displays results.
