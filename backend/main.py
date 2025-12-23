from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os
from pathlib import Path
import google.generativeai as genai
import mediapipe as mp
import cv2
import numpy as np
import json
import time
from dotenv import load_dotenv

load_dotenv()

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

# Configure Gemini
GENAI_API_KEY = os.getenv("GEMINI_API_KEY")
if GENAI_API_KEY:
    genai.configure(api_key=GENAI_API_KEY)

# Initialize MediaPipe
mp_pose = None
pose = None
try:
    if hasattr(mp, 'solutions'):
        mp_pose = mp.solutions.pose
        pose = mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5)
    else:
        print("Warning: mediapipe.solutions not found. Pose tracking will be disabled.")
except Exception as e:
    print(f"Warning: Failed to initialize MediaPipe: {e}")

@app.get("/")
def read_root():
    return {"message": "AI Coach Backend is running"}

def analyze_video_with_gemini(video_path):
    if not GENAI_API_KEY:
        # Return mock data if no key provided
        return {
            "shots": [
                {
                    "timestamp_of_outcome": "0:05.0",
                    "result": "missed",
                    "shot_type": "Jump shot",
                    "feedback": "Mock feedback: Check API key."
                }
            ]
        }
    
    print("Uploading video to Gemini...")
    video_file = genai.upload_file(path=video_path)
    
    # Wait for processing
    while video_file.state.name == "PROCESSING":
        print('.', end='', flush=True)
        time.sleep(1)
        video_file = genai.get_file(video_file.name)

    if video_file.state.name == "FAILED":
        raise ValueError(f"Video processing failed: {video_file.state.name}")

    print("\nGenerating analysis...")
    model = genai.GenerativeModel(model_name="gemini-3-flash-preview")
    
    prompt = """
    Analyze this basketball video and output a JSON object with the following structure for each shot attempt:
    {
        "shots": [
            {
                "timestamp_of_outcome": "MM:SS.s",
                "result": "made" or "missed",
                "shot_type": "description of shot",
                "feedback": "Constructive coaching feedback based on form",
                "total_shots_made_so_far": int,
                "total_shots_missed_so_far": int
            }
        ]
    }
    Only output valid JSON.
    """
    
    response = model.generate_content([video_file, prompt], request_options={"timeout": 600})
    
    try:
        # Extract JSON from code block if present
        text = response.text
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0]
        elif "```" in text:
            text = text.split("```")[1].split("```")[0]
            
        return json.loads(text)
    except Exception as e:
        print(f"Error parsing Gemini response: {e}")
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
    
    # Process every 5th frame to speed up
    process_every_n = 5
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
            
        if frame_count % process_every_n == 0:
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(rgb_frame)
            
            if results.pose_landmarks:
                head = results.pose_landmarks.landmark[0] # Nose/Head
                tracking_data.append({
                    "frame": frame_count,
                    "timestamp": frame_count / fps,
                    "head_x": head.x,
                    "head_y": head.y
                })
        
        frame_count += 1
        
    cap.release()
    return tracking_data, fps, width, height

@app.post("/process-video")
async def process_video(file: UploadFile = File(...)):
    try:
        file_path = UPLOAD_DIR / file.filename
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # 1. Get AI Analysis
        analysis_result = analyze_video_with_gemini(file_path)
        
        # 2. Get Motion Tracking (Optional: can be disabled for speed)
        tracking_result, fps, width, height = process_pose_tracking(file_path)
        
        # Cleanup
        os.remove(file_path)
        
        return {
            "analysis": analysis_result,
            "tracking": tracking_result,
            "metadata": {
                "fps": fps,
                "width": width,
                "height": height
            }
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
