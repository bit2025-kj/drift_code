"""
Cloud storage utility — Cloudinary when CLOUDINARY_URL is set, local filesystem fallback.
"""
import os
import asyncio
from fastapi import HTTPException
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
    if _is_ephemeral_host():
        raise HTTPException(
            status_code=503,
            detail=(
                "Stockage cloud non configuré. Ajoutez CLOUDINARY_URL sur Render "
                "avant de publier des fichiers."
            ),
        )
    return _upload_local(content, path)


def _is_ephemeral_host() -> bool:
    return any(
        os.getenv(name)
        for name in ("RENDER", "RENDER_SERVICE_ID", "RENDER_EXTERNAL_HOSTNAME")
    )


def _upload_cloudinary_sync(content: bytes, path: str, resource_type: str) -> str:
    import cloudinary.uploader
    # Keep the full path including extension as public_id so the returned URL
    # preserves the extension (e.g. .pdf, .mp4) — needed for type detection in Flutter.
    public_id = path.replace("\\", "/")
    result = cloudinary.uploader.upload(
        content,
        public_id=public_id,
        resource_type=resource_type,
        overwrite=True,
        use_filename=False,
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


def is_local_url(url: str | None) -> bool:
    return bool(url and url.startswith("/uploads/"))


def local_path_from_url(url: str) -> str:
    relative = url[len("/uploads/"):].lstrip("/")
    return os.path.join(settings.UPLOAD_DIR, relative)


def local_file_exists(url: str | None) -> bool:
    return bool(url and is_local_url(url) and os.path.exists(local_path_from_url(url)))


def missing_local_urls(urls: list[str | None]) -> list[str]:
    return [url for url in urls if is_local_url(url) and not local_file_exists(url)]
