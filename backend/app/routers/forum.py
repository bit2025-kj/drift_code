import os
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload

from app.config import settings
from app.database import get_db
from app.models import Discussion, DiscussionComment, ForumCategory, User
from app.schemas.forum import (
    DiscussionCreate, CommentCreate, DiscussionOut, DiscussionDetail,
    ForumStats, AuthorOut, CommentOut,
)
from app.utils.auth import get_current_user

router = APIRouter(prefix="/forum", tags=["Forum"])


def _author(user: User) -> AuthorOut:
    return AuthorOut(id=user.id, full_name=user.full_name, avatar_url=user.avatar_url, points=user.points)


def _serialize_comment(c: DiscussionComment) -> CommentOut:
    replies = [_serialize_comment(r) for r in (c.replies or []) if r.is_active]
    return CommentOut(
        id=c.id,
        content=c.content,
        likes_count=c.likes_count,
        is_solution=c.is_solution,
        created_at=c.created_at,
        author=_author(c.author),
        media_urls=c.media_urls or [],
        parent_id=c.parent_id,
        replies=replies,
    )


@router.post("/upload-media")
async def upload_media(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    content_type = file.content_type or ""
    if not (content_type.startswith("image/") or content_type.startswith("video/")):
        raise HTTPException(status_code=400, detail="Seuls les images et vidéos sont acceptés")

    ext = os.path.splitext(file.filename or "file")[1] or ".bin"
    filename = f"{uuid.uuid4()}{ext}"
    forum_dir = os.path.join(settings.UPLOAD_DIR, "forum")
    os.makedirs(forum_dir, exist_ok=True)
    dest = os.path.join(forum_dir, filename)

    content = await file.read()
    with open(dest, "wb") as f:
        f.write(content)

    return {"url": f"/uploads/forum/{filename}"}


@router.get("/stats", response_model=ForumStats)
async def forum_stats(db: AsyncSession = Depends(get_db)):
    total_members = (await db.execute(select(func.count()).select_from(User).where(User.is_active == True))).scalar()
    total_discussions = (await db.execute(select(func.count()).select_from(Discussion).where(Discussion.is_active == True))).scalar()
    return ForumStats(total_members=total_members or 0, total_discussions=total_discussions or 0, online_count=216)


@router.get("/categories")
async def list_categories(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(ForumCategory).order_by(ForumCategory.order))
    cats = result.scalars().all()
    return [{"id": c.id, "name": c.name, "slug": c.slug, "icon": c.icon, "color": c.color} for c in cats]


@router.get("", response_model=list[DiscussionOut])
async def list_discussions(
    db: AsyncSession = Depends(get_db),
    category_id: int | None = Query(None),
    matiere_id: int | None = Query(None),
    q: str | None = Query(None),
    sort_by: str = Query("recent"),
    page: int = Query(1, ge=1),
    per_page: int = Query(20),
):
    stmt = (
        select(Discussion)
        .options(selectinload(Discussion.author), selectinload(Discussion.category), selectinload(Discussion.matiere))
        .where(Discussion.is_active == True)
    )
    if category_id:
        stmt = stmt.where(Discussion.category_id == category_id)
    if matiere_id:
        stmt = stmt.where(Discussion.matiere_id == matiere_id)
    if q:
        stmt = stmt.where(Discussion.title.ilike(f"%{q}%"))
    if sort_by == "popular":
        stmt = stmt.order_by(Discussion.views_count.desc())
    else:
        stmt = stmt.order_by(Discussion.created_at.desc())

    stmt = stmt.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(stmt)
    discussions = result.scalars().all()

    return [
        DiscussionOut(
            **{k: getattr(d, k) for k in ["id", "title", "content", "views_count", "likes_count", "comments_count", "is_pinned", "is_resolved", "created_at"]},
            author=_author(d.author),
            category_name=d.category.name if d.category else None,
            matiere_name=d.matiere.name if d.matiere else None,
            media_urls=d.media_urls or [],
        )
        for d in discussions
    ]


@router.post("", response_model=DiscussionOut, status_code=201)
async def create_discussion(
    data: DiscussionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    disc = Discussion(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        title=data.title,
        content=data.content,
        category_id=data.category_id,
        matiere_id=data.matiere_id,
        classe_id=data.classe_id,
        media_urls=data.media_urls,
    )
    db.add(disc)
    current_user.points += 20
    await db.commit()
    await db.refresh(disc)

    return DiscussionOut(
        **{k: getattr(disc, k) for k in ["id", "title", "content", "views_count", "likes_count", "comments_count", "is_pinned", "is_resolved", "created_at"]},
        author=_author(current_user),
        media_urls=disc.media_urls or [],
    )


@router.get("/{discussion_id}", response_model=DiscussionDetail)
async def get_discussion(discussion_id: str, db: AsyncSession = Depends(get_db)):
    stmt = (
        select(Discussion)
        .options(
            selectinload(Discussion.author),
            selectinload(Discussion.category),
            selectinload(Discussion.matiere),
            selectinload(Discussion.comments).selectinload(DiscussionComment.author),
            selectinload(Discussion.comments).selectinload(DiscussionComment.replies).selectinload(DiscussionComment.author),
        )
        .where(Discussion.id == discussion_id)
    )
    result = await db.execute(stmt)
    disc = result.scalar_one_or_none()
    if not disc:
        raise HTTPException(status_code=404, detail="Discussion introuvable")
    disc.views_count += 1
    await db.commit()

    top_level = [c for c in disc.comments if not c.parent_id and c.is_active]
    comments = [_serialize_comment(c) for c in top_level]

    return DiscussionDetail(
        **{k: getattr(disc, k) for k in ["id", "title", "content", "views_count", "likes_count", "comments_count", "is_pinned", "is_resolved", "created_at"]},
        author=_author(disc.author),
        category_name=disc.category.name if disc.category else None,
        matiere_name=disc.matiere.name if disc.matiere else None,
        media_urls=disc.media_urls or [],
        comments=comments,
    )


@router.post("/{discussion_id}/comments", status_code=201)
async def add_comment(
    discussion_id: str,
    data: CommentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    comment = DiscussionComment(
        id=str(uuid.uuid4()),
        discussion_id=discussion_id,
        user_id=current_user.id,
        content=data.content,
        parent_id=data.parent_id,
        media_urls=data.media_urls,
    )
    db.add(comment)
    disc_result = await db.execute(select(Discussion).where(Discussion.id == discussion_id))
    disc = disc_result.scalar_one_or_none()
    if disc:
        disc.comments_count += 1
    current_user.points += 10
    await db.commit()
    return {"message": "Commentaire ajouté", "id": comment.id}


@router.post("/{discussion_id}/like")
async def like_discussion(
    discussion_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(select(Discussion).where(Discussion.id == discussion_id, Discussion.is_active == True))
    disc = result.scalar_one_or_none()
    if not disc:
        raise HTTPException(status_code=404, detail="Discussion introuvable")
    disc.likes_count += 1
    await db.commit()
    return {"likes_count": disc.likes_count}


@router.post("/{discussion_id}/comments/{comment_id}/like")
async def like_comment(
    discussion_id: str,
    comment_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(DiscussionComment).where(
            DiscussionComment.id == comment_id,
            DiscussionComment.discussion_id == discussion_id,
        )
    )
    comment = result.scalar_one_or_none()
    if not comment:
        raise HTTPException(status_code=404, detail="Commentaire introuvable")
    comment.likes_count += 1
    await db.commit()
    return {"likes_count": comment.likes_count}


@router.patch("/{discussion_id}/comments/{comment_id}/solution")
async def mark_as_solution(
    discussion_id: str,
    comment_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    disc_result = await db.execute(
        select(Discussion).where(Discussion.id == discussion_id, Discussion.user_id == current_user.id)
    )
    disc = disc_result.scalar_one_or_none()
    if not disc:
        raise HTTPException(status_code=403, detail="Seul l'auteur peut marquer une solution")

    comment_result = await db.execute(
        select(DiscussionComment).where(
            DiscussionComment.id == comment_id,
            DiscussionComment.discussion_id == discussion_id,
        )
    )
    comment = comment_result.scalar_one_or_none()
    if not comment:
        raise HTTPException(status_code=404, detail="Commentaire introuvable")

    comment.is_solution = not comment.is_solution
    disc.is_resolved = comment.is_solution
    await db.commit()
    return {"is_solution": comment.is_solution, "discussion_resolved": disc.is_resolved}


@router.delete("/{discussion_id}", status_code=204)
async def delete_discussion(
    discussion_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(select(Discussion).where(Discussion.id == discussion_id))
    disc = result.scalar_one_or_none()
    if not disc:
        raise HTTPException(status_code=404, detail="Discussion introuvable")
    if disc.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Action non autorisée")
    disc.is_active = False
    await db.commit()
    return
