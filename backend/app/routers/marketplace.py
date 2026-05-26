import os
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_
from sqlalchemy.orm import selectinload

from app.config import settings
from app.database import get_db
from app.models import Product, Purchase, TeacherProfile, User
from app.models.marketplace import TeacherRequest
from app.schemas.marketplace import (
    ProductOut, ProductCreate, ProductUpdate, ProductListResponse,
    PurchaseResponse, MarketplaceFilter,
    TeacherRequestCreate, TeacherRequestOut, AdminReviewRequest,
)
from app.utils.auth import get_current_user

router = APIRouter(prefix="/marketplace", tags=["Marketplace"])

_MEDIA_TYPES = {
    "image/jpeg": "image", "image/png": "image", "image/gif": "image",
    "image/webp": "image", "application/pdf": "pdf",
    "video/mp4": "video", "video/quicktime": "video",
    "video/x-msvideo": "video", "video/x-matroska": "video",
}


def _enrich_product(p: Product) -> ProductOut:
    out = ProductOut.model_validate(p)
    out.matiere_name = p.matiere.name if p.matiere else None
    out.classe_name = p.classe.name if p.classe else None
    out.level_name = p.level.name if p.level else None
    if p.teacher and p.teacher.user:
        out.teacher_name = p.teacher.user.full_name
        out.teacher_verified = p.teacher.is_verified
    out.teacher_id = p.teacher_id
    discount = p.discount_percent
    out.effective_price = int(p.price * (1 - discount / 100)) if discount > 0 else p.price
    out.media_urls = p.media_urls or []
    out.pack_items = p.pack_items or []
    return out


def _teacher_options():
    return [
        selectinload(Product.matiere),
        selectinload(Product.classe),
        selectinload(Product.level),
        selectinload(Product.teacher).selectinload(TeacherProfile.user),
    ]


# ── Media upload ──────────────────────────────────────────────────────────────

@router.post("/upload-media")
async def upload_media(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    content_type = file.content_type or ""
    media_type = _MEDIA_TYPES.get(content_type)
    if not media_type:
        raise HTTPException(
            status_code=400,
            detail="Type de fichier non supporté. Acceptés: images, PDF, vidéos.",
        )

    ext = os.path.splitext(file.filename or "file")[1] or ".bin"
    filename = f"{uuid.uuid4()}{ext}"
    dest_dir = os.path.join(settings.UPLOAD_DIR, "marketplace")
    os.makedirs(dest_dir, exist_ok=True)
    dest = os.path.join(dest_dir, filename)

    content = await file.read()
    with open(dest, "wb") as f:
        f.write(content)

    url = f"/uploads/marketplace/{filename}"
    return {"url": url, "type": media_type, "name": file.filename or filename}


# ── Teacher request ───────────────────────────────────────────────────────────

@router.post("/teacher-request", response_model=TeacherRequestOut, status_code=201)
async def submit_teacher_request(
    data: TeacherRequestCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.is_teacher:
        raise HTTPException(status_code=400, detail="Vous êtes déjà enseignant")

    existing = await db.execute(
        select(TeacherRequest).where(TeacherRequest.user_id == current_user.id)
    )
    req = existing.scalar_one_or_none()

    if req:
        if req.status == "pending":
            raise HTTPException(status_code=400, detail="Une demande est déjà en attente")
        if req.status == "approved":
            raise HTTPException(status_code=400, detail="Votre demande a déjà été approuvée")
        # rejected → allow resubmission
        req.bio = data.bio
        req.specialites = data.specialites
        req.etablissement = data.etablissement
        req.annees_experience = data.annees_experience
        req.justification = data.justification
        req.status = "pending"
        req.admin_note = None
        req.reviewed_at = None
    else:
        req = TeacherRequest(
            id=str(uuid.uuid4()),
            user_id=current_user.id,
            bio=data.bio,
            specialites=data.specialites,
            etablissement=data.etablissement,
            annees_experience=data.annees_experience,
            justification=data.justification,
        )
        db.add(req)

    await db.commit()
    await db.refresh(req)
    return req


@router.get("/teacher-request/me", response_model=TeacherRequestOut)
async def my_teacher_request(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(TeacherRequest).where(TeacherRequest.user_id == current_user.id)
    )
    req = result.scalar_one_or_none()
    if not req:
        raise HTTPException(status_code=404, detail="Aucune demande trouvée")
    return req


@router.post("/teacher-request/{request_id}/document")
async def upload_teacher_document(
    request_id: str,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(TeacherRequest).where(
            TeacherRequest.id == request_id,
            TeacherRequest.user_id == current_user.id,
        )
    )
    req = result.scalar_one_or_none()
    if not req:
        raise HTTPException(status_code=404, detail="Demande introuvable")

    ext = os.path.splitext(file.filename or "file")[1] or ".pdf"
    filename = f"teacher_doc_{uuid.uuid4()}{ext}"
    dest_dir = os.path.join(settings.UPLOAD_DIR, "teacher_docs")
    os.makedirs(dest_dir, exist_ok=True)
    dest = os.path.join(dest_dir, filename)

    content = await file.read()
    with open(dest, "wb") as f:
        f.write(content)

    req.document_url = f"/uploads/teacher_docs/{filename}"
    await db.commit()
    return {"document_url": req.document_url}


# ── Admin: review teacher requests ───────────────────────────────────────────

@router.get("/admin/teacher-requests")
async def list_teacher_requests(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    status: str | None = Query(None),
):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Accès réservé aux administrateurs")

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
        {
            "id": r.id,
            "user_id": r.user_id,
            "user_name": r.user.full_name if r.user else None,
            "user_email": r.user.email if r.user else None,
            "status": r.status,
            "bio": r.bio,
            "specialites": r.specialites,
            "etablissement": r.etablissement,
            "annees_experience": r.annees_experience,
            "document_url": r.document_url,
            "created_at": r.created_at,
        }
        for r in requests
    ]


@router.patch("/admin/teacher-requests/{request_id}")
async def review_teacher_request(
    request_id: str,
    data: AdminReviewRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Accès réservé aux administrateurs")
    if data.status not in ("approved", "rejected"):
        raise HTTPException(status_code=400, detail="Statut invalide")

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
        # Create teacher profile if absent
        tp_result = await db.execute(
            select(TeacherProfile).where(TeacherProfile.user_id == req.user_id)
        )
        tp = tp_result.scalar_one_or_none()
        if not tp:
            tp = TeacherProfile(
                id=str(uuid.uuid4()),
                user_id=req.user_id,
                bio=req.bio,
                specialites=req.specialites,
                etablissement=req.etablissement,
                annees_experience=req.annees_experience,
                is_verified=True,
            )
            db.add(tp)

    await db.commit()
    return {"status": req.status, "message": f"Demande {req.status}"}


# ── Teacher: manage own products ─────────────────────────────────────────────

@router.get("/me/products", response_model=list[ProductOut])
async def my_products(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.is_teacher:
        raise HTTPException(status_code=403, detail="Réservé aux enseignants")

    tp_result = await db.execute(
        select(TeacherProfile).where(TeacherProfile.user_id == current_user.id)
    )
    tp = tp_result.scalar_one_or_none()
    if not tp:
        return []

    stmt = (
        select(Product)
        .options(*_teacher_options())
        .where(Product.teacher_id == tp.id, Product.is_active == True)
        .order_by(Product.created_at.desc())
    )
    result = await db.execute(stmt)
    return [_enrich_product(p) for p in result.scalars().all()]


@router.post("/me/products", response_model=ProductOut, status_code=201)
async def create_product(
    data: ProductCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.is_teacher:
        raise HTTPException(status_code=403, detail="Réservé aux enseignants")

    tp_result = await db.execute(
        select(TeacherProfile).where(TeacherProfile.user_id == current_user.id)
    )
    tp = tp_result.scalar_one_or_none()
    if not tp:
        raise HTTPException(status_code=404, detail="Profil enseignant introuvable")

    # For packs, require at least 2 items
    if data.product_type == "pack" and len(data.pack_items) < 2:
        raise HTTPException(status_code=400, detail="Un pack doit contenir au moins 2 éléments")

    # Set thumbnail from first image media if not provided
    thumbnail = None
    for m in data.media_urls:
        if isinstance(m, dict) and m.get("type") == "image":
            thumbnail = m["url"]
            break

    product = Product(
        id=str(uuid.uuid4()),
        teacher_id=tp.id,
        title=data.title,
        description=data.description,
        price=data.price,
        product_type=data.product_type,
        matiere_id=data.matiere_id,
        classe_id=data.classe_id,
        level_id=data.level_id,
        discount_percent=data.discount_percent,
        media_urls=data.media_urls,
        pack_items=data.pack_items,
        thumbnail_url=thumbnail,
    )
    db.add(product)
    await db.commit()

    stmt = (
        select(Product)
        .options(*_teacher_options())
        .where(Product.id == product.id)
    )
    result = await db.execute(stmt)
    return _enrich_product(result.scalar_one())


@router.patch("/me/products/{product_id}", response_model=ProductOut)
async def update_product(
    product_id: str,
    data: ProductUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.is_teacher:
        raise HTTPException(status_code=403, detail="Réservé aux enseignants")

    tp_result = await db.execute(
        select(TeacherProfile).where(TeacherProfile.user_id == current_user.id)
    )
    tp = tp_result.scalar_one_or_none()

    stmt = (
        select(Product)
        .options(*_teacher_options())
        .where(Product.id == product_id, Product.teacher_id == (tp.id if tp else ""))
    )
    result = await db.execute(stmt)
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Produit introuvable ou non autorisé")

    if data.title is not None:
        product.title = data.title
    if data.description is not None:
        product.description = data.description
    if data.price is not None:
        product.price = data.price
    if data.discount_percent is not None:
        product.discount_percent = data.discount_percent
    if data.media_urls is not None:
        product.media_urls = data.media_urls
        # Refresh thumbnail
        for m in data.media_urls:
            if isinstance(m, dict) and m.get("type") == "image":
                product.thumbnail_url = m["url"]
                break
    if data.pack_items is not None:
        product.pack_items = data.pack_items
    if data.thumbnail_url is not None:
        product.thumbnail_url = data.thumbnail_url

    await db.commit()

    result2 = await db.execute(
        select(Product).options(*_teacher_options()).where(Product.id == product_id)
    )
    return _enrich_product(result2.scalar_one())


@router.delete("/me/products/{product_id}", status_code=204)
async def delete_my_product(
    product_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not current_user.is_teacher:
        raise HTTPException(status_code=403, detail="Réservé aux enseignants")

    tp_result = await db.execute(
        select(TeacherProfile).where(TeacherProfile.user_id == current_user.id)
    )
    tp = tp_result.scalar_one_or_none()

    result = await db.execute(
        select(Product).where(
            Product.id == product_id,
            Product.teacher_id == (tp.id if tp else ""),
        )
    )
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Produit introuvable ou non autorisé")

    product.is_active = False
    await db.commit()


# ── Public browsing ───────────────────────────────────────────────────────────

@router.get("", response_model=ProductListResponse)
async def list_products(
    db: AsyncSession = Depends(get_db),
    product_type: str | None = Query(None),
    matiere_id: int | None = Query(None),
    classe_id: int | None = Query(None),
    level_id: int | None = Query(None),
    max_price: int | None = Query(None),
    q: str | None = Query(None),
    sort_by: str = Query("popular"),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=50),
):
    stmt = (
        select(Product)
        .options(*_teacher_options())
        .where(Product.is_active == True)
    )
    if product_type:
        stmt = stmt.where(Product.product_type == product_type)
    if matiere_id:
        stmt = stmt.where(Product.matiere_id == matiere_id)
    if classe_id:
        stmt = stmt.where(Product.classe_id == classe_id)
    if level_id:
        stmt = stmt.where(Product.level_id == level_id)
    if max_price:
        stmt = stmt.where(Product.price <= max_price)
    if q:
        stmt = stmt.where(or_(Product.title.ilike(f"%{q}%"), Product.description.ilike(f"%{q}%")))

    if sort_by == "recent":
        stmt = stmt.order_by(Product.created_at.desc())
    elif sort_by == "price_asc":
        stmt = stmt.order_by(Product.price.asc())
    elif sort_by == "rating":
        stmt = stmt.order_by(Product.rating.desc())
    else:
        stmt = stmt.order_by(Product.purchases_count.desc())

    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = (await db.execute(count_stmt)).scalar()
    stmt = stmt.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(stmt)
    products = result.scalars().all()

    return ProductListResponse(
        total=total,
        page=page,
        per_page=per_page,
        items=[_enrich_product(p) for p in products],
    )


@router.get("/featured", response_model=list[ProductOut])
async def featured_products(db: AsyncSession = Depends(get_db)):
    stmt = (
        select(Product)
        .options(*_teacher_options())
        .where(Product.is_active == True, Product.is_featured == True)
        .order_by(Product.purchases_count.desc())
        .limit(8)
    )
    result = await db.execute(stmt)
    return [_enrich_product(p) for p in result.scalars().all()]


@router.get("/me/purchases")
async def my_purchases(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=50),
):
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
                "thumbnail_url": p.product.thumbnail_url if p.product else None,
                "purchased_at": p.purchased_at,
                "status": p.status,
            }
            for p in purchases
        ],
    }


@router.get("/{product_id}", response_model=ProductOut)
async def get_product(product_id: str, db: AsyncSession = Depends(get_db)):
    stmt = (
        select(Product)
        .options(*_teacher_options())
        .where(Product.id == product_id, Product.is_active == True)
    )
    result = await db.execute(stmt)
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Produit introuvable")
    product.views_count += 1
    await db.commit()
    return _enrich_product(product)


@router.post("/{product_id}/rate")
async def rate_product(
    product_id: str,
    rating: float = Query(..., ge=1.0, le=5.0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    existing = await db.execute(
        select(Purchase).where(Purchase.user_id == current_user.id, Purchase.product_id == product_id)
    )
    if not existing.scalar_one_or_none():
        raise HTTPException(status_code=403, detail="Vous devez avoir acheté ce produit pour le noter")

    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Produit introuvable")

    product.rating = round(
        (product.rating * product.ratings_count + rating) / (product.ratings_count + 1), 2
    )
    product.ratings_count += 1
    await db.commit()
    return {"rating": product.rating, "ratings_count": product.ratings_count}


@router.post("/{product_id}/purchase", response_model=PurchaseResponse)
async def purchase_product(
    product_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(select(Product).where(Product.id == product_id, Product.is_active == True))
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Produit introuvable")

    existing = await db.execute(
        select(Purchase).where(Purchase.user_id == current_user.id, Purchase.product_id == product_id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Vous avez déjà acheté ce produit")

    discount = product.discount_percent
    amount = int(product.price * (1 - discount / 100)) if discount > 0 else product.price

    if current_user.wallet_balance < amount:
        raise HTTPException(
            status_code=400,
            detail=f"Solde insuffisant. Solde actuel: {current_user.wallet_balance} FCFA",
        )

    current_user.wallet_balance -= amount
    product.purchases_count += 1

    purchase = Purchase(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        product_id=product_id,
        amount=amount,
    )
    db.add(purchase)
    await db.commit()

    return PurchaseResponse(
        purchase_id=purchase.id,
        product_title=product.title,
        amount_paid=amount,
        media_urls=product.media_urls or [],
        message="Achat réussi ! Accédez à votre contenu dès maintenant.",
    )
