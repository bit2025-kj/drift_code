from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from datetime import datetime, timezone

from app.database import get_db
from app.models import User, Document, Report
from app.models.marketplace import Product, Purchase, TeacherRequest
from app.models.user import TeacherProfile
from app.models.forum import Discussion
from app.models.quiz import QuizSession
from app.models.document import Favorite, Download
from app.models.badge import Badge, UserBadge
from app.utils.auth import get_current_admin
from app.utils.notify import push_notif
from app.schemas.admin import (
    AdminStats, UserListItem, UserDetailAdmin, UserActivity,
    UserStatusUpdate, ReportOut, ReportResolveRequest,
    TeacherRequestAdminOut, AdminReviewRequest,
)
import uuid

router = APIRouter(prefix="/admin", tags=["Administration"])


# ── Stats dashboard ──────────────────────────────────────────────────────────

@router.get("/stats", response_model=AdminStats)
async def get_stats(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    total_users = (await db.execute(select(func.count(User.id)))).scalar()
    active_users = (await db.execute(select(func.count(User.id)).where(User.is_active == True))).scalar()
    total_teachers = (await db.execute(select(func.count(User.id)).where(User.is_teacher == True))).scalar()
    total_documents = (await db.execute(select(func.count(Document.id)))).scalar()
    total_products = (await db.execute(select(func.count(Product.id)).where(Product.is_active == True))).scalar()
    pending_teacher_requests = (
        await db.execute(select(func.count(TeacherRequest.id)).where(TeacherRequest.status == "pending"))
    ).scalar()
    pending_reports = (
        await db.execute(select(func.count(Report.id)).where(Report.status == "pending"))
    ).scalar()

    return AdminStats(
        total_users=total_users or 0,
        active_users=active_users or 0,
        total_teachers=total_teachers or 0,
        total_documents=total_documents or 0,
        total_products=total_products or 0,
        pending_teacher_requests=pending_teacher_requests or 0,
        pending_reports=pending_reports or 0,
    )


# ── Gestion des utilisateurs ─────────────────────────────────────────────────

@router.get("/users", response_model=list[UserListItem])
async def list_users(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(get_current_admin),
    q: str | None = Query(None),
    is_active: bool | None = Query(None),
    is_teacher: bool | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(30, ge=1, le=100),
):
    stmt = select(User).order_by(User.created_at.desc())
    if q:
        stmt = stmt.where(
            User.full_name.ilike(f"%{q}%") | User.email.ilike(f"%{q}%")
        )
    if is_active is not None:
        stmt = stmt.where(User.is_active == is_active)
    if is_teacher is not None:
        stmt = stmt.where(User.is_teacher == is_teacher)

    stmt = stmt.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/users/{user_id}", response_model=UserDetailAdmin)
async def get_user_detail(
    user_id: str,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")

    downloads_count = (
        await db.execute(select(func.count(Download.id)).where(Download.user_id == user_id))
    ).scalar() or 0
    favorites_count = (
        await db.execute(select(func.count(Favorite.user_id)).where(Favorite.user_id == user_id))
    ).scalar() or 0
    quiz_sessions_count = (
        await db.execute(select(func.count(QuizSession.id)).where(QuizSession.user_id == user_id))
    ).scalar() or 0
    forum_posts_count = (
        await db.execute(select(func.count(Discussion.id)).where(Discussion.user_id == user_id))
    ).scalar() or 0
    purchases_count = (
        await db.execute(select(func.count(Purchase.id)).where(Purchase.user_id == user_id))
    ).scalar() or 0

    return UserDetailAdmin(
        id=user.id,
        full_name=user.full_name,
        email=user.email,
        phone=user.phone,
        ville=user.ville,
        is_active=user.is_active,
        is_teacher=user.is_teacher,
        is_admin=user.is_admin,
        points=user.points,
        wallet_balance=user.wallet_balance,
        current_streak=user.current_streak,
        active_days=user.active_days,
        created_at=user.created_at,
        activity=UserActivity(
            downloads_count=downloads_count,
            favorites_count=favorites_count,
            quiz_sessions_count=quiz_sessions_count,
            forum_posts_count=forum_posts_count,
            purchases_count=purchases_count,
        ),
    )


@router.patch("/users/{user_id}/status")
async def update_user_status(
    user_id: str,
    data: UserStatusUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    if user_id == admin.id:
        raise HTTPException(status_code=400, detail="Vous ne pouvez pas modifier votre propre statut")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")
    if user.is_admin:
        raise HTTPException(status_code=400, detail="Impossible de modifier un autre administrateur")

    user.is_active = data.is_active
    await db.commit()
    action = "activé" if data.is_active else "désactivé"
    return {"message": f"Compte {action} avec succès"}


# ── Demandes enseignant ───────────────────────────────────────────────────────

@router.get("/teacher-requests", response_model=list[TeacherRequestAdminOut])
async def list_teacher_requests(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(get_current_admin),
    status: str | None = Query(None),
):
    stmt = (
        select(TeacherRequest)
        .options(selectinload(TeacherRequest.user))
        .order_by(TeacherRequest.created_at.desc())
    )
    if status:
        stmt = stmt.where(TeacherRequest.status == status)

    result = await db.execute(stmt)
    requests = result.scalars().all()
    return [
        TeacherRequestAdminOut(
            id=r.id,
            status=r.status,
            bio=r.bio,
            specialites=r.specialites,
            etablissement=r.etablissement,
            annees_experience=r.annees_experience,
            justification=r.justification,
            document_url=r.document_url,
            admin_note=r.admin_note,
            created_at=r.created_at,
            reviewed_at=r.reviewed_at,
            user_id=r.user_id,
            user_name=r.user.full_name if r.user else None,
            user_email=r.user.email if r.user else None,
        )
        for r in requests
    ]


@router.patch("/teacher-requests/{request_id}")
async def review_teacher_request(
    request_id: str,
    data: AdminReviewRequest,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    if data.status not in ("approved", "rejected"):
        raise HTTPException(status_code=400, detail="Statut invalide (approved | rejected)")

    result = await db.execute(
        select(TeacherRequest)
        .options(selectinload(TeacherRequest.user))
        .where(TeacherRequest.id == request_id)
    )
    req = result.scalar_one_or_none()
    if not req:
        raise HTTPException(status_code=404, detail="Demande introuvable")

    req.status = data.status
    req.admin_note = data.admin_note
    req.reviewed_at = datetime.utcnow()

    if data.status == "approved" and req.user:
        req.user.is_teacher = True
        tp_res = await db.execute(
            select(TeacherProfile).where(TeacherProfile.user_id == req.user_id)
        )
        if not tp_res.scalar_one_or_none():
            db.add(TeacherProfile(
                id=str(uuid.uuid4()),
                user_id=req.user_id,
                bio=req.bio,
                specialites=req.specialites,
                etablissement=req.etablissement,
                annees_experience=req.annees_experience,
                is_verified=True,
            ))

    # Commit core approval — must succeed before badge/notification
    try:
        await db.commit()
    except Exception as e:
        await db.rollback()
        print(f"[ADMIN] review_teacher_request commit error: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur base de données: {type(e).__name__}: {e}")

    # Optional post-commit extras — badge + notification (best-effort, never block approval)
    try:
        if data.status == "approved" and req.user_id:
            badge_res = await db.execute(select(Badge).where(Badge.condition_type == "teacher"))
            teacher_badge = badge_res.scalar_one_or_none()
            if teacher_badge:
                already_earned = await db.execute(
                    select(UserBadge).where(
                        UserBadge.user_id == req.user_id,
                        UserBadge.badge_id == teacher_badge.id,
                    )
                )
                if not already_earned.scalar_one_or_none():
                    db.add(UserBadge(user_id=req.user_id, badge_id=teacher_badge.id))
                    # Update points via raw update to avoid stale object issues
                    from sqlalchemy import update as sa_update
                    await db.execute(
                        sa_update(User)
                        .where(User.id == req.user_id)
                        .values(points=User.points + teacher_badge.points_reward)
                    )

            await push_notif(
                db,
                user_id=req.user_id,
                type="teacher_approved",
                title="Candidature approuvée 🎉",
                body="Félicitations ! Vous êtes maintenant enseignant vérifié sur Nafa Edu. Vous pouvez créer et vendre vos cours.",
                data={"screen": "teacher_dashboard"},
            )
            await db.commit()

        elif data.status == "rejected":
            await push_notif(
                db,
                user_id=req.user_id,
                type="teacher_rejected",
                title="Candidature non retenue",
                body=f"Votre demande enseignant n'a pas été retenue.{(' Motif : ' + data.admin_note) if data.admin_note else ' Vous pouvez soumettre une nouvelle demande.'}",
                data={"screen": "teacher_request"},
            )
            await db.commit()
    except Exception as e:
        print(f"[ADMIN] post-approval badge/notif error (non-blocking): {e}")
        await db.rollback()

    return {"status": req.status, "message": f"Demande {req.status}"}


# ── Signalements ──────────────────────────────────────────────────────────────

@router.get("/reports", response_model=list[ReportOut])
async def list_reports(
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(get_current_admin),
    status: str | None = Query(None),
    content_type: str | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(30, ge=1, le=100),
):
    stmt = (
        select(Report)
        .options(selectinload(Report.reporter))
        .order_by(Report.created_at.desc())
    )
    if status:
        stmt = stmt.where(Report.status == status)
    if content_type:
        stmt = stmt.where(Report.content_type == content_type)

    stmt = stmt.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(stmt)
    reports = result.scalars().all()

    out = []
    for r in reports:
        title = await _get_content_title(db, r.content_type, r.content_id)
        out.append(ReportOut(
            id=r.id,
            reporter_id=r.reporter_id,
            reporter_name=r.reporter.full_name if r.reporter else None,
            content_type=r.content_type,
            content_id=r.content_id,
            content_title=title,
            reason=r.reason,
            description=r.description,
            status=r.status,
            admin_note=r.admin_note,
            resolved_by=r.resolved_by,
            resolved_at=r.resolved_at,
            created_at=r.created_at,
        ))
    return out


@router.patch("/reports/{report_id}")
async def resolve_report(
    report_id: str,
    data: ReportResolveRequest,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin),
):
    if data.status not in ("resolved", "dismissed"):
        raise HTTPException(status_code=400, detail="Statut invalide (resolved | dismissed)")

    result = await db.execute(select(Report).where(Report.id == report_id))
    report = result.scalar_one_or_none()
    if not report:
        raise HTTPException(status_code=404, detail="Signalement introuvable")

    report.status = data.status
    report.admin_note = data.admin_note
    report.resolved_by = admin.id
    report.resolved_at = datetime.utcnow()

    if data.delete_content and data.status == "resolved":
        await _delete_content(db, report.content_type, report.content_id)

    try:
        await db.commit()
    except Exception as e:
        await db.rollback()
        print(f"[ADMIN] resolve_report commit error: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur base de données: {type(e).__name__}: {e}")

    return {"status": report.status, "message": "Signalement traité"}


# ── Suppression de contenu ────────────────────────────────────────────────────

@router.delete("/documents/{document_id}")
async def delete_document(
    document_id: str,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    result = await db.execute(select(Document).where(Document.id == document_id))
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(status_code=404, detail="Document introuvable")
    await db.delete(doc)
    await db.commit()
    return {"message": "Document supprimé"}


@router.delete("/products/{product_id}")
async def delete_product(
    product_id: str,
    db: AsyncSession = Depends(get_db),
    _admin: User = Depends(get_current_admin),
):
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Produit introuvable")
    await db.delete(product)
    await db.commit()
    return {"message": "Produit supprimé"}


# ── Helpers internes ──────────────────────────────────────────────────────────

async def _get_content_title(db: AsyncSession, content_type: str, content_id: str) -> str | None:
    if content_type == "document":
        res = await db.execute(select(Document.title).where(Document.id == content_id))
        return res.scalar_one_or_none()
    if content_type == "product":
        res = await db.execute(select(Product.title).where(Product.id == content_id))
        return res.scalar_one_or_none()
    return None


async def _delete_content(db: AsyncSession, content_type: str, content_id: str):
    if content_type == "document":
        res = await db.execute(select(Document).where(Document.id == content_id))
        doc = res.scalar_one_or_none()
        if doc:
            await db.delete(doc)
    elif content_type == "product":
        res = await db.execute(select(Product).where(Product.id == content_id))
        product = res.scalar_one_or_none()
        if product:
            await db.delete(product)
