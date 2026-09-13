# Commercial Architecture & Infrastructure Roadmap

This document outlines the infrastructure, cost scaling, and deployment strategy for **AI Pickleball Form Coach** as it transitions from local development to a commercial mobile app on the Apple App Store & Google Play Store.

---

## 🏗️ 1. Production Architecture Overview

```text
[ Flutter Mobile App ]
     ├── Auth ────────► Firebase Auth or FastAPI JWT (App Store requires Apple & Google Sign-In)
     └── API ─────────► FastAPI Backend (Hosted on GCP Cloud Run / Render)
                            ├── DB ────────► Managed PostgreSQL (Railway / Render / Supabase Pro)
                            ├── Video ─────► Cloudflare R2 ($0 Egress Bandwidth Fees)
                            └── AI Engine ─► Gemini 2.0 Flash API + MediaPipe
```

---

## 💵 2. Monthly Cost Comparison (1,000 Active Users)

Video applications consume significant bandwidth. The primary infrastructure cost in production is **egress bandwidth** (users streaming/uploading video clips).

| Infrastructure Component | Supabase Pro | Firebase | Production Stack (GCP Cloud Run + Cloudflare R2) |
| :--- | :--- | :--- | :--- |
| **Auth** | Included | **$0** (Free up to 50k MAU) | **$0** (Firebase Auth or FastAPI JWT) |
| **Database** | $25.00 / mo | $10.00 / mo | $5.00 - $7.00 / mo (Managed Postgres) |
| **Video Storage (100 GB)**| $2.10 / mo | $2.60 / mo | $1.50 / mo (Cloudflare R2) |
| **Video Egress (500 GB)** | $45.00 / mo | $60.00 / mo | **$0.00** (Cloudflare R2 has **$0 egress fees**) |
| **FastAPI Backend Compute**| N/A | N/A | $0.00 - $8.00 / mo (GCP Cloud Run scale-to-zero) |
| **TOTAL ESTIMATED COST** | **~$72.10 / mo** | **~$72.60 / mo** | **~$6.50 – $16.50 / mo** |

> **Cost Tip**: Cloudflare R2 provides **$0 egress fees**, saving over 90% compared to AWS S3, Firebase, or Supabase Storage when serving video content.

---

## 📱 3. App Store Compliance Requirements

1. **Social Login Requirement (Apple Guideline 4.8)**:
   - If your commercial app offers third-party logins (like Google Sign-In), Apple **requires** offering **Sign in with Apple**.
   - Using **Firebase Auth** or **FastAPI JWT with OAuth2** handles Apple and Google Sign-In compliance out-of-the-box.
2. **Video Compression**:
   - Transcode uploaded videos to 720p/1080p H.264 before saving to cloud buckets to keep bandwidth low and uploads under 3 seconds.

---

## 🗺️ 4. 3-Phase Deployment Strategy

### **Phase 1: Local Development ($0/mo - Current Phase)**
- **Auth**: FastAPI Native JWT Auth (`pyjwt` + `passlib`).
- **Database**: Local SQLite (`app.db` via SQLAlchemy).
- **Storage**: Local disk storage (`backend/uploads/`).
- **Benefits**: 100% free, unlimited storage/users during local dev, zero cloud project limits.

### **Phase 2: Closed Beta & TestFlight ($0 – $5/mo)**
- **Compute**: Deploy FastAPI to **GCP Cloud Run** or **Render** (free scale-to-zero compute).
- **Storage**: Attach **Cloudflare R2** for video storage (10 GB free tier).
- **Auth**: Connect **Firebase Auth** for free email, Apple, and Google sign-in.

### **Phase 3: Public Commercial Launch**
- Attach hosted PostgreSQL database when paid subscribers onboard.
- Frontend Flutter app architecture stays 100% identical.
