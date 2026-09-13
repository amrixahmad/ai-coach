import os
import uuid
import datetime
from sqlalchemy import create_engine, Column, String, DateTime, ForeignKey, JSON
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship

raw_db_url = os.getenv("DATABASE_URL")
if raw_db_url:
    if raw_db_url.startswith("postgres://"):
        raw_db_url = raw_db_url.replace("postgres://", "postgresql://", 1)
    SQLALCHEMY_DATABASE_URL = raw_db_url
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
else:
    SQLALCHEMY_DATABASE_URL = "sqlite:///./app.db"
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def generate_uuid():
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=generate_uuid)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    analyses = relationship("Analysis", back_populates="owner")

class Analysis(Base):
    __tablename__ = "analyses"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    video_url = Column(String, nullable=True)
    gemini_analysis = Column(JSON, nullable=True)
    tracking_data = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    owner = relationship("User", back_populates="analyses")

def init_db():
    Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
