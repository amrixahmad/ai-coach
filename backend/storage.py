import os
import logging
from pathlib import Path
import boto3
from botocore.exceptions import BotoCoreError, ClientError

logger = logging.getLogger("storage")

# Cloudflare R2 / S3 Environment Variables
R2_ACCOUNT_ID = os.getenv("R2_ACCOUNT_ID")
R2_ACCESS_KEY_ID = os.getenv("R2_ACCESS_KEY_ID")
R2_SECRET_ACCESS_KEY = os.getenv("R2_SECRET_ACCESS_KEY")
R2_BUCKET_NAME = os.getenv("R2_BUCKET_NAME", "pickleball-videos")
R2_PUBLIC_DOMAIN = os.getenv("R2_PUBLIC_DOMAIN")  # e.g., https://pub-xxx.r2.dev
R2_CUSTOM_ENDPOINT = os.getenv("R2_ENDPOINT_URL")

s3_client = None

if R2_ACCESS_KEY_ID and R2_SECRET_ACCESS_KEY:
    try:
        endpoint_url = R2_CUSTOM_ENDPOINT
        if not endpoint_url and R2_ACCOUNT_ID:
            endpoint_url = f"https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
        
        if endpoint_url:
            s3_client = boto3.client(
                "s3",
                endpoint_url=endpoint_url,
                aws_access_key_id=R2_ACCESS_KEY_ID,
                aws_secret_access_key=R2_SECRET_ACCESS_KEY,
                region_name="auto"
            )
            print("Cloudflare R2 S3 client initialized successfully.")
    except Exception as e:
        print(f"Failed to initialize Cloudflare R2 client: {e}")

def upload_file_to_r2(local_path: Path, object_key: str) -> str | None:
    """
    Uploads a local file to Cloudflare R2 bucket.
    Returns the public HTTPS URL if successful, or None if R2 is not configured / upload fails.
    """
    if not s3_client:
        return None
    
    try:
        extra_args = {}
        path_str = str(local_path).lower()
        if path_str.endswith(".mp4"):
            extra_args["ContentType"] = "video/mp4"
        elif path_str.endswith(".mov"):
            extra_args["ContentType"] = "video/quicktime"

        s3_client.upload_file(
            str(local_path),
            R2_BUCKET_NAME,
            object_key,
            ExtraArgs=extra_args
        )
        print(f"Successfully uploaded {object_key} to R2 bucket '{R2_BUCKET_NAME}'")
        
        if R2_PUBLIC_DOMAIN:
            base = R2_PUBLIC_DOMAIN.rstrip("/")
            return f"{base}/{object_key}"
        elif R2_ACCOUNT_ID:
            return f"https://{R2_BUCKET_NAME}.{R2_ACCOUNT_ID}.r2.cloudflarestorage.com/{object_key}"
        else:
            return f"/{R2_BUCKET_NAME}/{object_key}"
    except (BotoCoreError, ClientError, Exception) as err:
        print(f"Cloudflare R2 upload error for {object_key}: {err}")
        return None
