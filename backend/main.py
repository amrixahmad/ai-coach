from fastapi import FastAPI, UploadFile, File, HTTPException, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import shutil
import os
from pathlib import Path
from google import genai
from google.genai import types
import mediapipe as mp
import cv2
import numpy as np
import json
import time
import re
from dotenv import load_dotenv
from sqlalchemy.orm import Session

from database import init_db, get_db, User, Analysis
from auth import hash_password, verify_password, create_access_token, get_current_user

load_dotenv()

# Initialize SQLite DB tables on startup
init_db()

app = FastAPI()

# Add CORS Middleware to allow Web requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

# Serve uploaded videos as static files
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Configure Gemini Client
GENAI_API_KEY = os.getenv("GEMINI_API_KEY")
client = None
if GENAI_API_KEY:
    client = genai.Client(api_key=GENAI_API_KEY)

# Initialize MediaPipe
mp_pose = None
pose = None
try:
    if hasattr(mp, 'solutions'):
        mp_pose = mp.solutions.pose
    else:
        import mediapipe.python.solutions.pose as mp_pose
    
    if mp_pose:
        pose = mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5)
        print("MediaPipe initialized successfully.")
    else:
        print("Warning: Could not load mediapipe.solutions.pose. Tracking disabled.")

except Exception as e:
    print(f"Warning: MediaPipe initialization failed: {e}. Pose tracking will be disabled.")

# Pydantic Schemas for Auth
class UserRegister(BaseModel):
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

@app.get("/")
def read_root():
    return {"message": "AI Pickleball Coach Backend is running"}

@app.post("/auth/register")
def register(user_data: UserRegister, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    user = User(
        email=user_data.email,
        hashed_password=hash_password(user_data.password)
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    token = create_access_token(user.id, user.email)
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {"id": user.id, "email": user.email}
    }

@app.post("/auth/login")
def login(user_data: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == user_data.email).first()
    if not user or not verify_password(user_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    token = create_access_token(user.id, user.email)
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {"id": user.id, "email": user.email}
    }

def calculate_angle(a, b, c):
    """Calculates 2D angle (in degrees) at joint 'b' given 3 points [x, y]"""
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)
    radians = np.arctan2(c[1] - b[1], c[0] - b[0]) - np.arctan2(a[1] - b[1], a[0] - b[0])
    angle = np.abs(radians * 180.0 / np.pi)
    if angle > 180.0:
        angle = 360.0 - angle
    return round(float(angle), 1)

def analyze_video_with_gemini(video_path):
    if not client:
        # Return mock data if no key provided
        return {
            "shots": [
                {
                    "timestamp_of_outcome": "0:05.0",
                    "result": "good",
                    "shot_type": "Dink",
                    "feedback": "Mock feedback: Good shoulder push dink. Check API key."
                }
            ]
        }
    
    print("Uploading video to Gemini...")
    video_file = client.files.upload(file=video_path)
    
    while video_file.state.name == "PROCESSING":
        print('.', end='', flush=True)
        time.sleep(1)
        video_file = client.files.get(name=video_file.name)

    if video_file.state.name == "FAILED":
        raise ValueError(f"Video processing failed: {video_file.state.name}")

    print("\nGenerating analysis...")
    
    prompt = """
    Analyze this pickleball video clip and output a JSON object with the following structure for each stroke or shot attempt:
    {
        "shots": [
            {
                "timestamp_of_outcome": "MM:SS.s",
                "result": "good" or "missed" or "illegal_serve",
                "shot_type": "Dink" or "Serve" or "Third-Shot Drop" or "Drive" or "Overhead Smash",
                "feedback": "Constructive coaching feedback on paddle path, wrist stability, knee bend depth, and court positioning",
                "total_shots_made_so_far": int,
                "total_shots_missed_so_far": int
            }
        ]
    }
    Only output valid JSON.
    """
    
    models_to_try = ['gemini-3.6-flash', 'gemini-2.5-flash', 'gemini-1.5-flash']
    response = None
    last_error = None
    for m in models_to_try:
        try:
            print(f"Trying Gemini model: {m}")
            response = client.models.generate_content(
                model=m, 
                contents=[video_file, prompt],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json"
                )
            )
            if response:
                print(f"Successfully generated response with {m}")
                break
        except Exception as err:
            print(f"Model {m} failed: {err}")
            last_error = err

    if not response:
        raise last_error
    
    try:
        return json.loads(response.text)
    except Exception as e:
        print(f"Error parsing Gemini response: {e}")
        text = response.text
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0]
        elif "```" in text:
            text = text.split("```")[1].split("```")[0]
        try:
            return json.loads(text)
        except:
            return {"error": "Failed to parse analysis", "raw_response": response.text}

def process_pose_tracking(video_path):
    cap = cv2.VideoCapture(str(video_path))
    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    
    tracking_data = []
    
    if pose is None:
        cap.release()
        return tracking_data, fps, width, height

    frame_count = 0
    process_every_n = 5
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
            
        if frame_count % process_every_n == 0:
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(rgb_frame)
            
            if results.pose_landmarks:
                landmarks = results.pose_landmarks.landmark
                head = landmarks[0]

                # Right Arm (12: shoulder, 14: elbow, 16: wrist)
                shoulder_r = [landmarks[12].x, landmarks[12].y]
                elbow_r = [landmarks[14].x, landmarks[14].y]
                wrist_r = [landmarks[16].x, landmarks[16].y]
                elbow_angle_r = calculate_angle(shoulder_r, elbow_r, wrist_r)

                # Right Leg (24: hip, 26: knee, 28: ankle)
                hip_r = [landmarks[24].x, landmarks[24].y]
                knee_r = [landmarks[26].x, landmarks[26].y]
                ankle_r = [landmarks[28].x, landmarks[28].y]
                knee_angle_r = calculate_angle(hip_r, knee_r, ankle_r)

                tracking_data.append({
                    "frame": frame_count,
                    "timestamp": frame_count / fps if fps > 0 else frame_count / 30.0,
                    "head_x": head.x,
                    "head_y": head.y,
                    "elbow_angle": elbow_angle_r,
                    "knee_angle": knee_angle_r,
                    "wrist_x": wrist_r[0],
                    "wrist_y": wrist_r[1]
                })
        
        frame_count += 1
        
    cap.release()
    return tracking_data, fps, width, height

@app.post("/process-video")
async def process_video(
    file: UploadFile = File(...), 
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        user_upload_dir = UPLOAD_DIR / user.id
        user_upload_dir.mkdir(parents=True, exist_ok=True)
        
        timestamp = int(time.time())
        clean_filename = re.sub(r'[^a-zA-Z0-9_.-]', '_', file.filename or 'upload.mp4')
        saved_filename = f"{timestamp}_{clean_filename}"
        file_path = user_upload_dir / saved_filename
        
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # 1. Get AI Analysis
        analysis_result = analyze_video_with_gemini(file_path)
        
        # 2. Get Motion Tracking
        tracking_result, fps, width, height = process_pose_tracking(file_path)
        
        # 3. Save to local SQLite Database & serve via StaticFiles URL
        video_url = f"http://localhost:8000/uploads/{user.id}/{saved_filename}"
        
        analysis_record = Analysis(
            user_id=user.id,
            video_url=video_url,
            gemini_analysis=analysis_result,
            tracking_data=tracking_result
        )
        db.add(analysis_record)
        db.commit()
        
        return {
            "analysis": analysis_result,
            "tracking": tracking_result,
            "metadata": {
                "fps": fps,
                "width": width,
                "height": height,
                "video_url": video_url
            }
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/analyses")
def get_user_analyses(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    records = db.query(Analysis).filter(Analysis.user_id == user.id).order_by(Analysis.created_at.desc()).all()
    return [
        {
            "id": rec.id,
            "video_url": rec.video_url,
            "created_at": rec.created_at.isoformat() if rec.created_at else None,
            "gemini_analysis": rec.gemini_analysis,
            "tracking_data": rec.tracking_data
        }
        for rec in records
    ]

@app.delete("/analyses/{analysis_id}")
def delete_analysis(
    analysis_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    record = db.query(Analysis).filter(Analysis.id == analysis_id, Analysis.user_id == user.id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Analysis not found")
    db.delete(record)
    db.commit()
    return {"message": "Deleted successfully"}

