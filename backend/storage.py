import os
import logging
from pathlib import Path
import boto3
from botocore.exceptions import BotoCoreError, ClientError

logger = logging.getLogger("storage")

def get_s3_client():
    account_id = os.getenv("R2_ACCOUNT_ID")
    access_key = os.getenv("R2_ACCESS_KEY_ID")
    secret_key = os.getenv("R2_SECRET_ACCESS_KEY")
    custom_endpoint = os.getenv("R2_ENDPOINT_URL")

    if access_key and secret_key:
        endpoint_url = custom_endpoint
        if not endpoint_url and account_id:
            endpoint_url = f"https://{account_id}.r2.cloudflarestorage.com"
        
        if endpoint_url:
            try:
                return boto3.client(
                    "s3",
                    endpoint_url=endpoint_url,
                    aws_access_key_id=access_key,
                    aws_secret_access_key=secret_key,
                    region_name="auto"
                )
            except Exception as e:
                print(f"Error creating boto3 client: {e}")
    return None

def upload_file_to_r2(local_path: Path, object_key: str) -> str | None:
    """
    Uploads a local file to Cloudflare R2 bucket.
    Returns the public HTTPS URL if successful, or None if R2 is not configured / upload fails.
    """
    client = get_s3_client()
    if not client:
        print("Cloudflare R2 client not configured. Skipping R2 upload.")
        return None
    
    bucket_name = os.getenv("R2_BUCKET_NAME", "pickleball-videos")
    public_domain = os.getenv("R2_PUBLIC_DOMAIN")
    account_id = os.getenv("R2_ACCOUNT_ID")

    try:
        extra_args = {}
        path_str = str(local_path).lower()
        if path_str.endswith(".mp4"):
            extra_args["ContentType"] = "video/mp4"
        elif path_str.endswith(".mov"):
            extra_args["ContentType"] = "video/quicktime"

        print(f"Attempting R2 upload to bucket '{bucket_name}' for key '{object_key}'...")
        client.upload_file(
            str(local_path),
            bucket_name,
            object_key,
            ExtraArgs=extra_args
        )
        print(f"Successfully uploaded {object_key} to R2 bucket '{bucket_name}'")
        
        if public_domain:
            base = public_domain.rstrip("/")
            return f"{base}/{object_key}"
        elif account_id:
            return f"https://{bucket_name}.{account_id}.r2.cloudflarestorage.com/{object_key}"
        else:
            return f"/{bucket_name}/{object_key}"
    except (BotoCoreError, ClientError, Exception) as err:
        print(f"Cloudflare R2 upload error for {object_key}: {err}")
        return None
