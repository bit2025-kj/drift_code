from fastapi import APIRouter, Depends, Query, UploadFile, File, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from app.database import get_db
from app.models import User, Download, Favorite, QuizSession, Discussion, Purchase, UserBadge, Badge, Document
from app.models.quiz import Quiz
from app.models.education import Matiere
from app.schemas.user import UserProfile, UserStats, UpdateProfileRequest, BadgeOut
from app.schemas.document import DocumentOut, DocumentListResponse
from app.utils.auth import get_current_user
from app.config import settings
import os

router = APIRouter(prefix="/users", tags=["Utilisateurs"])


@router.get("/me", response_model=UserProfile)
async def get_my_profile(current_user: User = Depends(get_current_user)):
    out = UserProfile.model_validate(current_user)
    out.level_name = current_user.level.name if current_user.level else None
    out.classe_name = current_user.classe.name if current_user.classe else None
    return out


@router.patch("/me", response_model=UserProfile)
async def update_profile(
    data: UpdateProfileRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    for field, value in data.model_dump(exclude_none=True).items():
        setattr(current_user, field, value)
    await db.commit()
    await db.refresh(current_user)
    out = UserProfile.model_validate(current_user)
    out.level_name = current_user.level.name if current_user.level else None
    out.classe_name = current_user.classe.name if current_user.classe else None
    return out


@router.post("/me/avatar", response_model=UserProfile)
async def upload_avatar(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    content = await file.read()
    ext = os.path.splitext(file.filename or "avatar.jpg")[1].lower()
    if ext not in {'.jpg', '.jpeg', '.png', '.webp'}:
        raise HTTPException(status_code=415, detail="Format non supporté. Utilisez JPG, PNG ou WebP.")
    if len(content) > 5 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Image trop volumineuse (max 5 Mo)")

    avatars_dir = os.path.join(settings.UPLOAD_DIR, "avatars")
    os.makedirs(avatars_dir, exist_ok=True)

    for old_ext in ('.jpg', '.jpeg', '.png', '.webp'):
        old = os.path.join(avatars_dir, f"{current_user.id}{old_ext}")
        if os.path.exists(old):
            os.remove(old)

    dest = os.path.join(avatars_dir, f"{current_user.id}{ext}")
    with open(dest, "wb") as f:
        f.write(content)

    current_user.avatar_url = f"/uploads/avatars/{current_user.id}{ext}"
    await db.commit()
    await db.refresh(current_user)
    out = UserProfile.model_validate(current_user)
    out.level_name = current_user.level.name if current_user.level else None
    out.classe_name = current_user.classe.name if current_user.classe else None
    return out


@router.get("/me/activity")
async def get_my_activity(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: int = Query(20, ge=1, le=50),
):
    items = []

    dl_rows = (await db.execute(
        select(Download.downloaded_at, Document.title, Download.is_corrige)
        .join(Document, Download.document_id == Document.id, isouter=True)
        .where(Download.user_id == current_user.id)
        .order_by(Download.downloaded_at.desc())
        .limit(limit)
    )).all()
    for downloaded_at, title, is_corrige in dl_rows:
        items.append({
            "type": "download",
            "title": "Téléchargement" + (" (corrigé)" if is_corrige else ""),
            "subtitle": title or "Document",
            "timestamp": downloaded_at.isoformat() if downloaded_at else None,
            "extra": {},
        })

    quiz_rows = (await db.execute(
        select(QuizSession.completed_at, QuizSession.score)
        .where(QuizSession.user_id == current_user.id, QuizSession.is_completed == True)
        .order_by(QuizSession.completed_at.desc())
        .limit(limit)
    )).all()
    for completed_at, score in quiz_rows:
        items.append({
            "type": "quiz",
            "title": "Quiz complété",
            "subtitle": f"Score : {round(float(score or 0), 1)} %",
            "timestamp": completed_at.isoformat() if completed_at else None,
            "extra": {"score": round(float(score or 0), 1)},
        })

    forum_rows = (await db.execute(
        select(Discussion.created_at, Discussion.title)
        .where(Discussion.user_id == current_user.id)
        .order_by(Discussion.created_at.desc())
        .limit(limit)
    )).all()
    for created_at, title in forum_rows:
        items.append({
            "type": "forum",
            "title": "Publication forum",
            "subtitle": title or "Discussion",
            "timestamp": created_at.isoformat() if created_at else None,
            "extra": {},
        })

    purchase_rows = (await db.execute(
        select(Purchase.purchased_at, Document.title, Purchase.amount)
        .join(Document, Purchase.product_id == Document.id, isouter=True)
        .where(Purchase.user_id == current_user.id)
        .order_by(Purchase.purchased_at.desc())
        .limit(limit)
    )).all()
    for purchased_at, title, amount in purchase_rows:
        items.append({
            "type": "purchase",
            "title": "Achat",
            "subtitle": title or "Produit",
            "timestamp": purchased_at.isoformat() if purchased_at else None,
            "extra": {"amount": amount},
        })

    items.sort(key=lambda x: x["timestamp"] or "", reverse=True)
    return items[:limit]


@router.get("/me/stats", response_model=UserStats)
async def get_my_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    total_downloads = (
        await db.execute(select(func.count()).where(Download.user_id == current_user.id))
    ).scalar()
    total_favorites = (
        await db.execute(select(func.count()).where(Favorite.user_id == current_user.id))
    ).scalar()
    quiz_result = await db.execute(
        select(func.count(), func.avg(QuizSession.score))
        .where(QuizSession.user_id == current_user.id, QuizSession.is_completed == True)
    )
    quiz_count, avg_score = quiz_result.one()
    total_forum = (
        await db.execute(select(func.count()).where(Discussion.user_id == current_user.id))
    ).scalar()
    total_purchases = (
        await db.execute(select(func.count()).where(Purchase.user_id == current_user.id))
    ).scalar()
    badges_count = (
        await db.execute(select(func.count()).where(UserBadge.user_id == current_user.id))
    ).scalar()

    # Real subject_progress: quiz sessions grouped by matière
    subj_stmt = (
        select(Matiere.name, func.count(QuizSession.id), func.avg(QuizSession.score))
        .join(Quiz, QuizSession.quiz_id == Quiz.id)
        .join(Matiere, Quiz.matiere_id == Matiere.id)
        .where(QuizSession.user_id == current_user.id, QuizSession.is_completed == True)
        .group_by(Matiere.id, Matiere.name)
        .order_by(func.count(QuizSession.id).desc())
        .limit(6)
    )
    subj_rows = (await db.execute(subj_stmt)).all()
    subject_progress = [
        {
            "matiere_name": row[0],
            "session_count": row[1],
            "completion": round(float(row[2] or 0), 1),
        }
        for row in subj_rows
    ]

    # Real revision hours: 15 min per quiz session (average quiz duration)
    revision_hours = round((quiz_count or 0) * 0.25, 1)

    return UserStats(
        total_downloads=total_downloads or 0,
        total_favorites=total_favorites or 0,
        total_quiz_sessions=quiz_count or 0,
        avg_quiz_score=round(avg_score or 0, 1),
        total_forum_posts=total_forum or 0,
        total_purchases=total_purchases or 0,
        badges_count=badges_count or 0,
        revision_hours=revision_hours,
        subject_progress=subject_progress,
    )


@router.get("/me/badges", response_model=list[BadgeOut])
async def get_my_badges(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Badge, UserBadge.earned_at)
        .join(UserBadge, Badge.id == UserBadge.badge_id)
        .where(UserBadge.user_id == current_user.id)
    )
    rows = result.all()
    return [
        BadgeOut(
            id=badge.id, name=badge.name, description=badge.description,
            icon=badge.icon, color=badge.color, earned_at=earned_at,
        )
        for badge, earned_at in rows
    ]


@router.get("/leaderboard")
async def get_leaderboard(db: AsyncSession = Depends(get_db), limit: int = 20):
    result = await db.execute(
        select(User.id, User.full_name, User.avatar_url, User.points, User.current_streak)
        .where(User.is_active == True)
        .order_by(User.points.desc())
        .limit(limit)
    )
    rows = result.all()
    return [
        {"rank": i + 1, "id": r.id, "full_name": r.full_name,
         "avatar_url": r.avatar_url, "points": r.points, "streak": r.current_streak}
        for i, r in enumerate(rows)
    ]


@router.get("/me/favorites", response_model=DocumentListResponse)
async def get_my_favorites(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=50),
):
    from app.routers.documents import _enrich
    stmt = (
        select(Document)
        .join(Favorite, Favorite.document_id == Document.id)
        .options(
            selectinload(Document.level), selectinload(Document.classe),
            selectinload(Document.matiere), selectinload(Document.type_examen),
        )
        .where(Favorite.user_id == current_user.id)
        .order_by(Favorite.created_at.desc())
    )
    total = (await db.execute(select(func.count()).select_from(stmt.subquery()))).scalar()
    stmt = stmt.offset((page - 1) * per_page).limit(per_page)
    docs = (await db.execute(stmt)).scalars().all()
    return DocumentListResponse(total=total, page=page, per_page=per_page, items=[_enrich(d) for d in docs])


@router.get("/me/downloads")
async def get_my_downloads(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=50),
):
    stmt = (
        select(Download)
        .options(
            selectinload(Download.document).selectinload(Document.level),
            selectinload(Download.document).selectinload(Document.matiere),
        )
        .where(Download.user_id == current_user.id)
        .order_by(Download.downloaded_at.desc())
    )
    total = (await db.execute(select(func.count()).select_from(stmt.subquery()))).scalar()
    stmt = stmt.offset((page - 1) * per_page).limit(per_page)
    downloads = (await db.execute(stmt)).scalars().all()
    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "items": [
            {
                "id": dl.id,
                "document_id": dl.document_id,
                "title": dl.document.title if dl.document else None,
                "is_corrige": dl.is_corrige,
                "downloaded_at": dl.downloaded_at,
                "level_name": dl.document.level.name if dl.document and dl.document.level else None,
                "matiere_name": dl.document.matiere.name if dl.document and dl.document.matiere else None,
            }
            for dl in downloads
        ],
    }


@router.get("/me/purchases")
async def get_my_purchases(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=50),
):
    from app.models import Product
    stmt = (
        select(Purchase)
        .options(selectinload(Purchase.product))
        .where(Purchase.user_id == current_user.id)
        .order_by(Purchase.purchased_at.desc())
    )
    total = (await db.execute(select(func.count()).select_from(stmt.subquery()))).scalar()
    stmt = stmt.offset((page - 1) * per_page).limit(per_page)
    purchases = (await db.execute(stmt)).scalars().all()
    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "items": [
            {
                "id": p.id,
                "product_id": p.product_id,
                "title": p.product.title if p.product else None,
                "amount_paid": p.amount,
                "media_urls": p.product.media_urls if p.product else [],
                "purchased_at": p.purchased_at,
                "status": p.status,
            }
            for p in purchases
        ],
    }
