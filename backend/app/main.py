from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
import os

from app.config import settings
from app.database import create_tables, AsyncSessionLocal, engine
from app.utils.seed_data import seed_database
from app.routers import auth, users, documents, quiz, forum, marketplace, education, chat, ai, notifications
from app.routers import sync


async def _apply_schema_migrations() -> None:
    """Add any columns that exist in models but are missing from the DB (safe: IF NOT EXISTS)."""
    migrations = [
        # Forum
        "ALTER TABLE discussions ADD COLUMN IF NOT EXISTS media_urls JSON DEFAULT '[]'",
        "ALTER TABLE discussion_comments ADD COLUMN IF NOT EXISTS media_urls JSON DEFAULT '[]'",
        # Marketplace
        "ALTER TABLE products ADD COLUMN IF NOT EXISTS thumbnail_url VARCHAR(500)",
        "ALTER TABLE products ADD COLUMN IF NOT EXISTS media_urls JSON DEFAULT '[]'",
        "ALTER TABLE products ADD COLUMN IF NOT EXISTS pack_items JSON DEFAULT '[]'",
        "ALTER TABLE products ADD COLUMN IF NOT EXISTS discount_percent INTEGER DEFAULT 0",
        "ALTER TABLE products ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE",
        "ALTER TABLE products ADD COLUMN IF NOT EXISTS views_count INTEGER DEFAULT 0",
        # Teacher requests
        "ALTER TABLE teacher_requests ADD COLUMN IF NOT EXISTS document_url VARCHAR(500)",
        "ALTER TABLE teacher_requests ADD COLUMN IF NOT EXISTS admin_note TEXT",
        # Documents
        "ALTER TABLE documents ADD COLUMN IF NOT EXISTS session VARCHAR(50)",
        "ALTER TABLE documents ADD COLUMN IF NOT EXISTS ratings_count INTEGER DEFAULT 0",
        "ALTER TABLE documents ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0",
        "ALTER TABLE downloads ADD COLUMN IF NOT EXISTS is_corrige BOOLEAN DEFAULT FALSE",
    ]
    async with engine.begin() as conn:
        for sql in migrations:
            try:
                await conn.execute(__import__('sqlalchemy').text(sql))
            except Exception:
                pass  # column may already exist or table doesn't exist yet


async def _retroactive_thumbnails() -> None:
    """Generate thumbnails for existing PDFs that don't have one yet."""
    import asyncio as _asyncio
    from app.routers.documents import _generate_thumbnail_sync, _thumb_path
    docs_dir = os.path.join(settings.UPLOAD_DIR, "documents")
    thumb_dir = os.path.join(settings.UPLOAD_DIR, "thumbnails")
    if not os.path.isdir(docs_dir):
        return
    for fname in os.listdir(docs_dir):
        if not fname.lower().endswith(".pdf"):
            continue
        doc_id = fname[:-4].split("_corrige")[0]  # skip corrige files
        if "_corrige" in fname:
            continue
        tp = _thumb_path(doc_id)
        if not os.path.exists(tp):
            pdf_path = os.path.join(docs_dir, fname)
            await _asyncio.to_thread(_generate_thumbnail_sync, pdf_path, tp)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await create_tables()
    await _apply_schema_migrations()
    async with AsyncSessionLocal() as db:
        await seed_database(db)
    os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
    os.makedirs(os.path.join(settings.UPLOAD_DIR, "documents"), exist_ok=True)
    os.makedirs(os.path.join(settings.UPLOAD_DIR, "thumbnails"), exist_ok=True)
    os.makedirs(os.path.join(settings.UPLOAD_DIR, "forum"), exist_ok=True)
    os.makedirs(os.path.join(settings.UPLOAD_DIR, "marketplace"), exist_ok=True)
    os.makedirs(os.path.join(settings.UPLOAD_DIR, "teacher_docs"), exist_ok=True)
    os.makedirs(os.path.join(settings.UPLOAD_DIR, "avatars"), exist_ok=True)
    import asyncio as _asyncio
    _asyncio.create_task(_retroactive_thumbnails())
    yield


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="API de la plateforme éducative Nafa Edu — Burkina Faso",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(documents.router)
app.include_router(quiz.router)
app.include_router(forum.router)
app.include_router(marketplace.router)
app.include_router(education.router)
app.include_router(chat.router)
app.include_router(ai.router)
app.include_router(sync.router)
app.include_router(notifications.router)

# Servir les fichiers uploadés — doit être monté APRÈS les routers API
# pour que /uploads/... ne masque pas d'éventuelles routes API sur ce préfixe.
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.UPLOAD_DIR), name="uploads")


@app.get("/", tags=["Health"])
async def root():
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "✅ Nafa Edu API opérationnelle",
        "docs": "/docs",
    }


@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok"}
