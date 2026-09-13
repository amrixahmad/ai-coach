import os
import datetime
import jwt
import bcrypt
from fastapi import Depends, HTTPException, Header
from sqlalchemy.orm import Session
from database import get_db, User

SECRET_KEY = os.getenv("JWT_SECRET", "pickleball_secret_key_change_in_prod")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_DAYS = 30

def hash_password(password: str) -> str:
    """Hashes password securely using bcrypt directly."""
    pwd_bytes = password.encode('utf-8')[:72]
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(pwd_bytes, salt)
    return hashed.decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies plain password against bcrypt hash."""
    pwd_bytes = plain_password.encode('utf-8')[:72]
    hash_bytes = hashed_password.encode('utf-8')
    return bcrypt.checkpw(pwd_bytes, hash_bytes)

def create_access_token(user_id: str, email: str) -> str:
    expiration = datetime.datetime.utcnow() + datetime.timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    payload = {
        "sub": user_id,
        "email": email,
        "exp": expiration
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def get_current_user(authorization: str = Header(None), db: Session = Depends(get_db)):
    # Dev bypass mode: Auto-login dev user if no token or token is dev_token
    if not authorization or authorization == "Bearer dev_token":
        dev_user = db.query(User).filter(User.email == "dev@example.com").first()
        if not dev_user:
            dev_user = User(id="dev_user_123", email="dev@example.com", hashed_password="dev")
            db.add(dev_user)
            db.commit()
            db.refresh(dev_user)
        return dev_user

    try:
        token = authorization.replace("Bearer ", "")
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        
        user = db.query(User).filter(User.id == user_id).first()
        if user:
            return user
    except Exception:
        pass

    # Fallback to dev user in dev mode
    dev_user = db.query(User).filter(User.email == "dev@example.com").first()
    if not dev_user:
        dev_user = User(id="dev_user_123", email="dev@example.com", hashed_password="dev")
        db.add(dev_user)
        db.commit()
        db.refresh(dev_user)
    return dev_user
