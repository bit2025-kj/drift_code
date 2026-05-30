from fastapi import APIRouter, Depends, Query, UploadFile, File, Form, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_, delete
from sqlalchemy.orm import selectinload
from pydantic import BaseModel
from app.database import get_db
from app.models import Document, DocumentLike, Favorite, Download, EducationLevel, Classe, Matiere, TypeExamen, User, Report
from app.schemas.document import DocumentOut, DocumentListResponse, FavoriteToggleResponse
from app.schemas.admin import ReportCreate
from app.utils.auth import ensure_owner, get_current_user
from app.utils.notify import push_notif
from app.utils.storage import (
    local_path_from_url,
    upload_file as storage_upload,
)
from app.config import settings
import asyncio, uuid, os, io as _io


_CORRIGE_IMAGE_EXTS = {'.jpg', '.jpeg', '.png', '.webp', '.gif'}

router = APIRouter(prefix="/documents", tags=["Banque de Sujets"])


_IMAGE_EXTS = {'.jpg', '.jpeg', '.png', '.webp', '.gif'}


def _thumb_path(doc_id: str) -> str:
    return os.path.join(settings.UPLOAD_DIR, "thumbnails", f"{doc_id}.jpg")


def _generate_thumbnail_sync(pdf_path: str, thumb_path: str) -> None:
    try:
        import pypdfium2 as pdfium
        doc = pdfium.PdfDocument(pdf_path)
        page = doc[0]
        width = page.get_width()
        scale = 300.0 / width if width > 0 else 1.0
        bitmap = page.render(scale=scale, rotation=0)
        bitmap.to_pil().save(thumb_path, "JPEG", quality=85)
        doc.close()
    except Exception:
        pass


def _enrich(doc: Document) -> DocumentOut:
    out = DocumentOut.model_validate(doc)
    out.level_name = doc.level.name if doc.level else None
    out.classe_name = doc.classe.name if doc.classe else None
    out.matiere_name = doc.matiere.name if doc.matiere else None
    out.type_examen_name = doc.type_examen.name if doc.type_examen else None
    if doc.file_url:
        ext = os.path.splitext(doc.file_url.split("?")[0])[1].lower()
        out.file_type = 'image' if ext in _IMAGE_EXTS else 'pdf'
        if out.file_type == 'pdf':
            if doc.thumbnail_url:
                out.thumbnail_url = doc.thumbnail_url
            elif os.path.exists(_thumb_path(doc.id)):
                out.thumbnail_url = f"/uploads/thumbnails/{doc.id}.jpg"
    if doc.corrige_url:
        ext = os.path.splitext(doc.corrige_url)[1].lower()
        out.corrige_url = doc.corrige_url
        out.corrige_file_type = 'image' if ext in _CORRIGE_IMAGE_EXTS else 'pdf'
    out.uploaded_by = doc.uploaded_by
    if doc.uploader:
        out.uploader_name = doc.uploader.full_name
        out.uploader_avatar = doc.uploader.avatar_url
    return out


@router.get("", response_model=DocumentListResponse)
async def list_documents(
    db: AsyncSession = Depends(get_db),
    level_id: int | None = Query(None),
    classe_id: int | None = Query(None),
    matiere_id: int | None = Query(None),
    type_examen_id: int | None = Query(None),
    annee: int | None = Query(None),
    has_corrige: bool | None = Query(None),
    is_official: bool | None = Query(None),
    q: str | None = Query(None),
    sort_by: str = Query("recent"),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=50),
):
    stmt = (
        select(Document)
        .options(
            selectinload(Document.level),
            selectinload(Document.classe),
            selectinload(Document.matiere),
            selectinload(Document.type_examen),
            selectinload(Document.uploader),
        )
        .where(Document.is_approved == True)
    )

    if level_id:
        stmt = stmt.where(Document.level_id == level_id)
    if classe_id:
        stmt = stmt.where(Document.classe_id == classe_id)
    if matiere_id:
        stmt = stmt.where(Document.matiere_id == matiere_id)
    if type_examen_id:
        stmt = stmt.where(Document.type_examen_id == type_examen_id)
    if annee:
        stmt = stmt.where(Document.annee == annee)
    if has_corrige is not None:
        stmt = stmt.where(Document.has_corrige == has_corrige)
    if is_official is not None:
        stmt = stmt.where(Document.is_official == is_official)
    if q:
        stmt = stmt.where(or_(
            Document.title.ilike(f"%{q}%"),
            Document.description.ilike(f"%{q}%"),
        ))

    if sort_by == "popular":
        stmt = stmt.order_by(Document.downloads_count.desc())
    elif sort_by == "likes":
        stmt = stmt.order_by(Document.likes_count.desc())
    else:
        stmt = stmt.order_by(Document.created_at.desc())

    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = (await db.execute(count_stmt)).scalar()

    stmt = stmt.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(stmt)
    docs = result.scalars().all()

    return DocumentListResponse(total=total, page=page, per_page=per_page, items=[_enrich(d) for d in docs])


@router.get("/trending", response_model=list[DocumentOut])
async def trending_documents(db: AsyncSession = Depends(get_db), limit: int = 10):
    stmt = (
        select(Document)
        .options(
            selectinload(Document.level), selectinload(Document.classe),
            selectinload(Document.matiere), selectinload(Document.type_examen),
            selectinload(Document.uploader),
        )
        .where(Document.is_approved == True)
        .order_by(Document.likes_count.desc(), Document.downloads_count.desc())
        .limit(limit)
    )
    result = await db.execute(stmt)
    return [_enrich(d) for d in result.scalars().all()]


@router.get("/{document_id}", response_model=DocumentOut)
async def get_document(document_id: str, db: AsyncSession = Depends(get_db)):
    stmt = (
        select(Document)
        .options(
            selectinload(Document.level), selectinload(Document.classe),
            selectinload(Document.matiere), selectinload(Document.type_examen),
        )
        .where(Document.id == document_id)
    )
    result = await db.execute(stmt)
    doc = result.scalar_one_or_none()
    if not doc:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Document introuvable")
    doc.views_count += 1
    await db.commit()
    return _enrich(doc)


@router.post("/{document_id}/download")
async def download_document(
    document_id: str,
    is_corrige: bool = False,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(select(Document).where(Document.id == document_id))
    doc = result.scalar_one_or_none()
    if not doc:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Document introuvable")

    file_url = doc.corrige_url if is_corrige else doc.file_url

    # Local files on Render's ephemeral disk are lost on every restart.
    # Return a clear error early rather than letting the client download a 404.
    if file_url and file_url.startswith('/uploads/'):
        local_path = local_path_from_url(file_url)
        if not os.path.exists(local_path):
            raise HTTPException(
                status_code=404,
                detail="Ce fichier n'est plus disponible (le serveur a redémarré). "
                       "Configurez CLOUDINARY_URL sur Render pour éviter ce problème.",
            )

    dl = Download(user_id=current_user.id, document_id=document_id, is_corrige=is_corrige)
    db.add(dl)
    doc.downloads_count += 1
    current_user.points += 5
    await db.commit()

    return {"file_url": file_url, "title": doc.title}


@router.post("/{document_id}/favorite", response_model=FavoriteToggleResponse)
async def toggle_favorite(
    document_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Favorite).where(Favorite.user_id == current_user.id, Favorite.document_id == document_id)
    )
    fav = result.scalar_one_or_none()
    if fav:
        await db.delete(fav)
        await db.commit()
        return FavoriteToggleResponse(is_favorite=False, message="Retiré des favoris")
    else:
        db.add(Favorite(user_id=current_user.id, document_id=document_id))
        await db.commit()
        return FavoriteToggleResponse(is_favorite=True, message="Ajouté aux favoris")


@router.post("/{document_id}/like")
async def like_document(
    document_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(select(Document).where(Document.id == document_id))
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(status_code=404, detail="Document introuvable")

    existing = await db.execute(
        select(DocumentLike).where(
            DocumentLike.user_id == current_user.id,
            DocumentLike.document_id == document_id,
        )
    )
    like = existing.scalar_one_or_none()
    if like:
        await db.delete(like)
        doc.likes_count = max(0, doc.likes_count - 1)
        liked = False
    else:
        db.add(DocumentLike(user_id=current_user.id, document_id=document_id))
        doc.likes_count += 1
        liked = True

    if liked and doc.uploaded_by:
        await push_notif(
            db, doc.uploaded_by,
            type="document_like",
            title="J'aime sur votre sujet",
            body=f"{current_user.full_name} a aimé votre sujet « {doc.title[:60]} »",
            data={"document_id": document_id, "document_title": doc.title},
            exclude_user_id=current_user.id,
        )
    await db.commit()
    return {"liked": liked, "likes_count": doc.likes_count}


@router.post("/upload", response_model=DocumentOut, status_code=201)
async def upload_document(
    title: str = Form(...),
    description: str = Form(None),
    level_id: int = Form(...),
    classe_id: int = Form(None),
    matiere_id: int = Form(None),
    type_examen_id: int = Form(None),
    annee: int = Form(None),
    session: str = Form(None),
    is_official: bool = Form(False),
    file: UploadFile = File(...),
    corrige: UploadFile = File(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    max_bytes = settings.MAX_FILE_SIZE_MB * 1024 * 1024
    file_id = str(uuid.uuid4())
    ext = os.path.splitext(file.filename or "file.pdf")[1].lower() or ".pdf"

    chunk = await file.read(max_bytes + 1)
    if len(chunk) > max_bytes:
        raise HTTPException(status_code=413, detail=f"Fichier trop volumineux (max {settings.MAX_FILE_SIZE_MB} Mo)")
    size = len(chunk)

    file_resource_type = "image" if ext in _IMAGE_EXTS else "raw"
    file_url = await storage_upload(
        chunk,
        f"documents/{file_id}{ext}",
        resource_type=file_resource_type,
    )

    # Generate thumbnail for PDFs then upload to cloud
    thumbnail_url = None
    if ext == '.pdf':
        import tempfile
        with tempfile.NamedTemporaryFile(suffix=ext, delete=False) as tmp:
            tmp.write(chunk)
            tmp_path = tmp.name
        thumb_tmp = tmp_path + "_thumb.jpg"

        def _gen_and_upload():
            _generate_thumbnail_sync(tmp_path, thumb_tmp)
            if os.path.exists(thumb_tmp):
                with open(thumb_tmp, "rb") as tf:
                    return tf.read()
            return None

        thumb_bytes = await asyncio.to_thread(_gen_and_upload)
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        if thumb_bytes:
            thumbnail_url = await storage_upload(thumb_bytes, f"thumbnails/{file_id}.jpg", resource_type="image")
            try:
                os.unlink(thumb_tmp)
            except OSError:
                pass

    corrige_url = None
    has_corrige = False

    if corrige and corrige.filename:
        c_ext = os.path.splitext(corrige.filename)[1].lower() or ".pdf"
        c_bytes = await corrige.read(max_bytes + 1)
        corrige_resource_type = "image" if c_ext in _CORRIGE_IMAGE_EXTS else "raw"
        corrige_url = await storage_upload(
            c_bytes,
            f"documents/{file_id}_corrige{c_ext}",
            resource_type=corrige_resource_type,
        )
        has_corrige = True

    doc = Document(
        id=file_id,
        title=title,
        description=description,
        level_id=level_id,
        classe_id=classe_id,
        matiere_id=matiere_id,
        type_examen_id=type_examen_id,
        annee=annee,
        session=session,
        is_official=is_official,
        file_url=file_url,
        corrige_url=corrige_url,
        has_corrige=has_corrige,
        file_size_kb=size // 1024,
        uploaded_by=current_user.id,
        is_approved=True,
        thumbnail_url=thumbnail_url,
    )
    db.add(doc)
    await db.commit()

    result = await db.execute(
        select(Document)
        .options(
            selectinload(Document.level), selectinload(Document.classe),
            selectinload(Document.matiere), selectinload(Document.type_examen),
        )
        .where(Document.id == doc.id)
    )
    return _enrich(result.scalar_one())


# ── Modifier / Supprimer un document (propriétaire uniquement) ───────────────

class _DocUpdate(BaseModel):
    title: str | None = None
    description: str | None = None


@router.patch("/{document_id}", response_model=DocumentOut)
async def update_document(
    document_id: str,
    data: _DocUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Document)
        .options(selectinload(Document.level), selectinload(Document.classe),
                 selectinload(Document.matiere), selectinload(Document.type_examen),
                 selectinload(Document.uploader))
        .where(Document.id == document_id)
    )
    doc = result.scalar_one_or_none()
    if not doc:
        raise HTTPException(status_code=404, detail="Document introuvable")
    ensure_owner(current_user.id, doc.uploaded_by)
    if data.title is not None:
        doc.title = data.title
    if data.description is not None:
        doc.description = data.description
    await db.commit()
    await db.refresh(doc)
    return _enrich(doc)


@router.delete("/{document_id}", status_code=204)
async def delete_document_owner(
    document_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Document).where(Document.id == document_id)
    )

    doc = result.scalar_one_or_none()

    if not doc:
        raise HTTPException(status_code=404, detail="Document introuvable")

    ensure_owner(current_user.id, doc.uploaded_by)

    # Supprimer les dépendances AVANT le document
    await db.execute(
        delete(Download).where(Download.document_id == document_id)
    )

    await db.execute(
        delete(DocumentLike).where(
            DocumentLike.document_id == document_id
        )
    )

    await db.execute(
        delete(Favorite).where(
            Favorite.document_id == document_id
        )
    )

    await db.execute(
        delete(Report).where(
            Report.content_type == "document",
            Report.content_id == document_id,
        )
    )

    # Puis supprimer le document
    await db.delete(doc)

    await db.commit()


# ── Upload multi-pages (images → PDF) ────────────────────────────────────────

def _merge_images_to_pdf_sync(images_bytes: list[bytes]) -> bytes:
    """Merge a list of image byte buffers into a single multi-page PDF using Pillow."""
    from PIL import Image
    imgs = []
    for b in images_bytes:
        img = Image.open(_io.BytesIO(b))
        if img.mode != "RGB":
            img = img.convert("RGB")
        imgs.append(img)
    buf = _io.BytesIO()
    imgs[0].save(buf, format="PDF", save_all=True, append_images=imgs[1:], resolution=150.0)
    return buf.getvalue()


@router.post("/upload-pages", response_model=DocumentOut, status_code=201)
async def upload_multi_page_document(
    title: str = Form(...),
    description: str = Form(None),
    level_id: int = Form(...),
    classe_id: int = Form(None),
    matiere_id: int = Form(None),
    type_examen_id: int = Form(None),
    annee: int = Form(None),
    session: str = Form(None),
    is_official: bool = Form(False),
    pages: list[UploadFile] = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not pages:
        raise HTTPException(status_code=400, detail="Au moins une image est requise")
    if len(pages) > 20:
        raise HTTPException(status_code=400, detail="Maximum 20 pages par document")

    images_bytes = [await p.read() for p in pages]

    try:
        pdf_bytes = await asyncio.to_thread(_merge_images_to_pdf_sync, images_bytes)
    except Exception as e:
        raise HTTPException(status_code=422, detail=f"Impossible de fusionner les images : {e}")

    doc_id = str(uuid.uuid4())
    file_url = await storage_upload(
        pdf_bytes,
        f"documents/{doc_id}.pdf",
        resource_type="raw",
    )

    # Generate thumbnail from merged PDF
    thumbnail_url = None
    try:
        import tempfile
        with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp:
            tmp.write(pdf_bytes)
            tmp_path = tmp.name
        thumb_out = tmp_path + "_thumb.jpg"

        def _gen():
            _generate_thumbnail_sync(tmp_path, thumb_out)
            if os.path.exists(thumb_out):
                with open(thumb_out, "rb") as f:
                    return f.read()
            return None

        thumb_bytes = await asyncio.to_thread(_gen)
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        if thumb_bytes:
            thumbnail_url = await storage_upload(
                thumb_bytes, f"thumbnails/{doc_id}.jpg", resource_type="image"
            )
            try:
                os.unlink(thumb_out)
            except OSError:
                pass
    except Exception:
        pass

    doc = Document(
        id=doc_id,
        title=title,
        description=description,
        level_id=level_id,
        classe_id=classe_id,
        matiere_id=matiere_id,
        type_examen_id=type_examen_id,
        annee=annee,
        session=session,
        is_official=is_official,
        file_url=file_url,
        has_corrige=False,
        file_size_kb=len(pdf_bytes) // 1024,
        uploaded_by=current_user.id,
        is_approved=True,
        thumbnail_url=thumbnail_url,
    )
    db.add(doc)
    current_user.points += 20
    await db.commit()

    result = await db.execute(
        select(Document)
        .options(
            selectinload(Document.level), selectinload(Document.classe),
            selectinload(Document.matiere), selectinload(Document.type_examen),
        )
        .where(Document.id == doc.id)
    )
    return _enrich(result.scalar_one())


# ── Signalement ───────────────────────────────────────────────────────────────

@router.post("/{document_id}/report", status_code=201)
async def report_document(
    document_id: str,
    data: ReportCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    doc = (await db.execute(select(Document).where(Document.id == document_id))).scalar_one_or_none()
    if not doc:
        raise HTTPException(status_code=404, detail="Document introuvable")

    existing = await db.execute(
        select(Report).where(
            Report.reporter_id == current_user.id,
            Report.content_type == "document",
            Report.content_id == document_id,
            Report.status == "pending",
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Vous avez déjà signalé ce contenu")

    db.add(Report(
        id=str(uuid.uuid4()),
        reporter_id=current_user.id,
        content_type="document",
        content_id=document_id,
        reason=data.reason,
        description=data.description,
    ))
    await db.commit()
    return {"message": "Signalement envoyé, merci pour votre contribution"}
