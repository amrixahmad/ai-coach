# AI Basketball Coach

A mobile app that analyzes your basketball shot using Gemini and MediaPipe.

## Structure
- `mobile-app/`: Expo (React Native) app.
- `backend/`: FastAPI Python server (Analysis Engine).
- `prototype/`: Original Python proof-of-concept.

## Setup Instructions

### 1. Supabase Setup (Database & Auth)
1.  Create a project at [supabase.com](https://supabase.com).
2.  Go to the **SQL Editor** in your Supabase dashboard.
3.  Copy the contents of `backend/schema.sql` and run it to set up the tables and security policies.
4.  Get your **URL**, **Anon Key** (for App), and **Service Role Key** (for Backend).

### 2. Backend Setup (Python)
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
   - Add your keys:
     ```
     GEMINI_API_KEY=your_gemini_key
     SUPABASE_URL=your_supabase_url
     SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
     ```

5. Run the server:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

### 3. Mobile App Setup (Expo)
The frontend allows recording/uploading videos and viewing results.

1. Navigate to app: `cd mobile-app`
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set up Environment Variables:
   - Rename/Create `.env`
   - Add Supabase keys:
     ```
     EXPO_PUBLIC_SUPABASE_URL=your_supabase_url
     EXPO_PUBLIC_SUPABASE_ANON_KEY=your_anon_key
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
1. **Auth**: User logs in or signs up via the Mobile App.
2. **Input**: User picks a video.
3. **Processing**:
   - App uploads video to `http://<backend>/process-video` with Auth Token.
   - Backend verifies user.
   - Backend uploads video to Supabase Storage.
   - Backend uploads to Gemini for analysis + runs MediaPipe.
   - Backend saves results to Supabase Database.
4. **Result**: App displays results.
