from fastapi import FastAPI, UploadFile, File, HTTPException
import shutil
import os
from pathlib import Path

app = FastAPI()

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

@app.get("/")
def read_root():
    return {"message": "AI Coach Backend is running"}

@app.post("/process-video")
async def process_video(file: UploadFile = File(...)):
    try:
        file_path = UPLOAD_DIR / file.filename
        with file_path.open("wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # TODO: Trigger Gemini + MediaPipe processing here
        
        return {"filename": file.filename, "status": "uploaded", "message": "Processing started"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
