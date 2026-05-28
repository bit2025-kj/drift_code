"""
Cloud storage utility — Cloudinary when CLOUDINARY_URL is set, local filesystem fallback.
"""
import os
import asyncio
from app.config import settings

_cloudinary_configured = False


def _init_cloudinary() -> bool:
    global _cloudinary_configured
    if _cloudinary_configured:
        return True
    url = getattr(settings, "CLOUDINARY_URL", "")
    if not url:
        return False
    try:
        import cloudinary
        cloudinary.config(cloudinary_url=url)
        _cloudinary_configured = True
        return True
    except Exception as e:
        print(f"[storage] Cloudinary init error: {e}")
        return False


async def upload_file(content: bytes, path: str, resource_type: str = "auto") -> str:
    """
    Upload bytes to cloud (Cloudinary) or local filesystem.

    `path` is used as the public_id on Cloudinary and as the relative path
    under UPLOAD_DIR locally (e.g. 'documents/abc123.pdf').

    Returns the accessible URL string.
    """
    if _init_cloudinary():
        return await asyncio.to_thread(_upload_cloudinary_sync, content, path, resource_type)
    return _upload_local(content, path)


def _upload_cloudinary_sync(content: bytes, path: str, resource_type: str) -> str:
    import cloudinary.uploader
    public_id = path.replace("\\", "/")
    if "." in os.path.basename(public_id):
        public_id = os.path.splitext(public_id)[0]
    result = cloudinary.uploader.upload(
        content,
        public_id=public_id,
        resource_type=resource_type,
        overwrite=True,
    )
    return result["secure_url"]


def _upload_local(content: bytes, path: str) -> str:
    dest = os.path.join(settings.UPLOAD_DIR, path)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "wb") as f:
        f.write(content)
    return f"/uploads/{path}"


def file_url(path: str) -> str:
    """Convert a relative storage path to a URL (local only; Cloudinary returns full URL at upload time)."""
    return f"/uploads/{path}"
