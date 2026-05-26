from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from app.database import get_db
from app.models import Download, Favorite, QuizSession, User, Document
from app.utils.auth import get_current_user

router = APIRouter(prefix="/sync", tags=["Synchronisation Offline"])


@router.get("/state")
async def get_user_sync_state(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Retourne l'état complet de l'utilisateur pour initialiser/synchroniser
    l'app après une période hors ligne.
    """
    # Favoris
    favs_result = await db.execute(
        select(Favorite.document_id).where(Favorite.user_id == current_user.id)
    )
    favorite_ids = [row[0] for row in favs_result.all()]

    # Téléchargements
    downloads_result = await db.execute(
        select(Download.document_id, Download.downloaded_at)
        .where(Download.user_id == current_user.id)
        .order_by(Download.downloaded_at.desc())
        .limit(50)
    )
    download_ids = [{"id": row[0], "downloaded_at": row[1].isoformat()} for row in downloads_result.all()]

    # Stats quiz
    quiz_result = await db.execute(
        select(func.count(), func.avg(QuizSession.score))
        .where(QuizSession.user_id == current_user.id, QuizSession.is_completed == True)
    )
    quiz_count, avg_score = quiz_result.one()

    return {
        "user_id": current_user.id,
        "points": current_user.points,
        "active_days": current_user.active_days,
        "current_streak": current_user.current_streak,
        "wallet_balance": current_user.wallet_balance,
        "favorite_document_ids": favorite_ids,
        "recent_downloads": download_ids,
        "quiz_stats": {
            "total_sessions": quiz_count or 0,
            "avg_score": round(avg_score or 0, 1),
        },
        "synced_at": __import__("datetime").datetime.utcnow().isoformat(),
    }


@router.post("/batch")
async def batch_sync(
    operations: list[dict],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Traite un batch d'opérations hors ligne en une seule requête.
    Format: [{"operation": "favorite_add", "entity_id": "doc-id"}, ...]
    """
    results = []

    for op in operations:
        operation = op.get("operation")
        entity_id = op.get("entity_id")

        try:
            if operation == "favorite_add":
                existing = await db.execute(
                    select(Favorite).where(Favorite.user_id == current_user.id, Favorite.document_id == entity_id)
                )
                if not existing.scalar_one_or_none():
                    db.add(Favorite(user_id=current_user.id, document_id=entity_id))
                results.append({"operation": operation, "entity_id": entity_id, "status": "ok"})

            elif operation == "favorite_remove":
                result = await db.execute(
                    select(Favorite).where(Favorite.user_id == current_user.id, Favorite.document_id == entity_id)
                )
                fav = result.scalar_one_or_none()
                if fav:
                    await db.delete(fav)
                results.append({"operation": operation, "entity_id": entity_id, "status": "ok"})

            else:
                results.append({"operation": operation, "entity_id": entity_id, "status": "unknown_operation"})

        except Exception as e:
            results.append({"operation": operation, "entity_id": entity_id, "status": "error", "detail": str(e)})

    await db.commit()
    return {"processed": len(results), "results": results}


@router.get("/favorites")
async def get_sync_favorites(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    since: str = Query(None, description="ISO datetime — retourne seulement les favoris ajoutés après cette date"),
):
    stmt = (
        select(Favorite)
        .options(
            selectinload(Favorite.document).selectinload(Document.level),
            selectinload(Favorite.document).selectinload(Document.matiere),
        )
        .where(Favorite.user_id == current_user.id)
        .order_by(Favorite.created_at.desc())
    )
    if since:
        from datetime import datetime
        try:
            since_dt = datetime.fromisoformat(since.replace("Z", "+00:00"))
            stmt = stmt.where(Favorite.created_at >= since_dt)
        except ValueError:
            pass
    result = await db.execute(stmt)
    favs = result.scalars().all()
    return [
        {
            "document_id": f.document_id,
            "added_at": f.created_at.isoformat(),
            "title": f.document.title if f.document else None,
            "level_name": f.document.level.name if f.document and f.document.level else None,
            "matiere_name": f.document.matiere.name if f.document and f.document.matiere else None,
            "file_url": f.document.file_url if f.document else None,
        }
        for f in favs
    ]


@router.get("/downloads")
async def get_sync_downloads(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: int = Query(50, ge=1, le=200),
    since: str = Query(None, description="ISO datetime — retourne seulement les téléchargements après cette date"),
):
    stmt = (
        select(Download)
        .options(
            selectinload(Download.document).selectinload(Document.level),
            selectinload(Download.document).selectinload(Document.matiere),
        )
        .where(Download.user_id == current_user.id)
        .order_by(Download.downloaded_at.desc())
        .limit(limit)
    )
    if since:
        from datetime import datetime
        try:
            since_dt = datetime.fromisoformat(since.replace("Z", "+00:00"))
            stmt = stmt.where(Download.downloaded_at >= since_dt)
        except ValueError:
            pass
    result = await db.execute(stmt)
    downloads = result.scalars().all()
    return [
        {
            "document_id": dl.document_id,
            "downloaded_at": dl.downloaded_at.isoformat(),
            "is_corrige": dl.is_corrige,
            "title": dl.document.title if dl.document else None,
            "file_url": (dl.document.corrige_url if dl.is_corrige else dl.document.file_url) if dl.document else None,
            "level_name": dl.document.level.name if dl.document and dl.document.level else None,
            "matiere_name": dl.document.matiere.name if dl.document and dl.document.matiere else None,
        }
        for dl in downloads
    ]


@router.get("/ping")
async def ping():
    return {"status": "online", "ts": __import__("datetime").datetime.utcnow().isoformat()}
