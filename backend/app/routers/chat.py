from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from sqlalchemy.orm import selectinload
from datetime import datetime, timezone
import asyncio
import uuid

from app.database import get_db
from app.models.user import User
from app.models.chat import ConversationThread, ConversationMessage, ChatDocument
from app.schemas.chat import (
    ConversationThreadOut, ConversationDetailOut, ConversationMessageOut,
    ChatDocumentOut, CreateConversationRequest, SendMessageRequest,
    ChatMessageResponse
)
from app.utils.auth import get_current_user
from app.config import settings
from mistralai import Mistral
from app.services.chat_service import (
    save_uploaded_file, process_document_file, generate_context_from_document
)

router = APIRouter(prefix="/ai", tags=["AI Chat"])

_SYSTEM_PROMPT = """Tu es l'assistant IA de Nafa Edu, une plateforme éducative pour les élèves et étudiants du Burkina Faso.
Tu aides les élèves à comprendre leurs cours, préparer leurs examens (BAC, BEPC, concours), et répondre à leurs questions académiques.
Tu réponds en français, de façon claire, pédagogique et encourageante.
Quand tu expliques un concept, donne des exemples concrets adaptés au contexte africain.
Sois concis mais complet. Si une question est hors sujet éducatif, redirige poliment vers les études."""


# ── Gestion des conversations ──────────────────────────────────────────────────

@router.post("/conversations", response_model=ConversationThreadOut)
async def create_conversation(
    data: CreateConversationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Créer une nouvelle conversation"""
    thread = ConversationThread(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        title=data.title,
        description=data.description,
    )
    db.add(thread)
    await db.commit()
    await db.refresh(thread)
    return ConversationThreadOut.model_validate(thread)


@router.get("/conversations", response_model=list[ConversationThreadOut])
async def list_conversations(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: int = 50,
):
    """Lister les conversations de l'utilisateur (offline-ready)"""
    stmt = (
        select(ConversationThread)
        .where(ConversationThread.user_id == current_user.id)
        .where(ConversationThread.is_active == True)
        .order_by(desc(ConversationThread.last_message_at))
        .limit(limit)
    )
    result = await db.execute(stmt)
    threads = result.scalars().all()
    return [ConversationThreadOut.model_validate(t) for t in threads]


@router.get("/conversations/{thread_id}", response_model=ConversationDetailOut)
async def get_conversation(
    thread_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Récupérer une conversation complète avec historique"""
    stmt = (
        select(ConversationThread)
        .where(ConversationThread.id == thread_id)
        .where(ConversationThread.user_id == current_user.id)
        .options(
            selectinload(ConversationThread.messages),
            selectinload(ConversationThread.documents)
        )
    )
    result = await db.execute(stmt)
    thread = result.scalar_one_or_none()
    
    if not thread:
        raise HTTPException(status_code=404, detail="Conversation non trouvée")
    
    return ConversationDetailOut(
        id=thread.id,
        title=thread.title,
        description=thread.description,
        is_active=thread.is_active,
        created_at=thread.created_at,
        updated_at=thread.updated_at,
        last_message_at=thread.last_message_at,
        messages=[ConversationMessageOut.model_validate(m) for m in thread.messages],
        documents=[ChatDocumentOut.model_validate(d) for d in thread.documents],
    )


@router.delete("/conversations/{thread_id}")
async def delete_conversation(
    thread_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Supprimer une conversation (soft delete)"""
    stmt = select(ConversationThread).where(
        ConversationThread.id == thread_id,
        ConversationThread.user_id == current_user.id,
    )
    result = await db.execute(stmt)
    thread = result.scalar_one_or_none()
    
    if not thread:
        raise HTTPException(status_code=404, detail="Conversation non trouvée")
    
    thread.is_active = False
    await db.commit()
    return {"status": "deleted"}


# ── Messages et Chat ───────────────────────────────────────────────────────────

@router.post("/conversations/{thread_id}/messages", response_model=ChatMessageResponse)
async def send_message(
    thread_id: str,
    data: SendMessageRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Envoyer un message et obtenir une réponse (compatible offline)"""
    
    # Vérifier que la conversation existe
    stmt = select(ConversationThread).where(
        ConversationThread.id == thread_id,
        ConversationThread.user_id == current_user.id,
    )
    result = await db.execute(stmt)
    thread = result.scalar_one_or_none()
    
    if not thread:
        raise HTTPException(status_code=404, detail="Conversation non trouvée")
    
    # Sauvegarder le message utilisateur
    user_message = ConversationMessage(
        id=str(uuid.uuid4()),
        thread_id=thread_id,
        role="user",
        content=data.content,
        document_id=data.document_id,
    )
    db.add(user_message)
    await db.flush()
    
    # Préparer le contexte (si document fourni)
    context_text = ""
    if data.document_id:
        doc_stmt = select(ChatDocument).where(ChatDocument.id == data.document_id)
        doc_result = await db.execute(doc_stmt)
        doc = doc_result.scalar_one_or_none()
        if doc and doc.extracted_text:
            context_text = f"\n[Document: {doc.filename}]\n{doc.extracted_text[:2000]}\n"
    
    # Générer la réponse avec l'API Mistral
    if not settings.MISTRAL_API_KEY:
        raise HTTPException(status_code=503, detail="Service IA non configuré")
    
    try:
        # Récupérer l'historique pour le contexte (les 10 plus récents)
        msg_stmt = (
            select(ConversationMessage)
            .where(ConversationMessage.thread_id == thread_id)
            .order_by(ConversationMessage.created_at.desc())
            .limit(10)  # Derniers 10 messages
        )
        msg_result = await db.execute(msg_stmt)
        history = list(reversed(msg_result.scalars().all()))
        
        # Construire les messages pour l'API
        messages = [
            {"role": m.role, "content": m.content}
            for m in history
        ]
        
        # Injecter le contexte du document dans le prompt système
        system_prompt = _SYSTEM_PROMPT
        if context_text:
            system_prompt += f"\n\nL'élève t'a partagé le contenu d'un document. Utilise-le pour répondre à ses questions :\n\n---\n{context_text}\n---"
        
        client = Mistral(api_key=settings.MISTRAL_API_KEY)
        response = await asyncio.to_thread(
            client.chat.complete,
            model="mistral-large-latest",
            messages=[
                {"role": "system", "content": system_prompt},
                *messages,
            ],
        )
        
        reply = response.choices[0].message.content if response.choices else "Erreur de génération."
        
        # Sauvegarder la réponse
        assistant_message = ConversationMessage(
            id=str(uuid.uuid4()),
            thread_id=thread_id,
            role="assistant",
            content=reply,
        )
        db.add(assistant_message)
        
        # Mettre à jour le timestamp de la conversation
        thread.last_message_at = datetime.now(timezone.utc)
        thread.updated_at = datetime.now(timezone.utc)
        
        await db.commit()
        await db.refresh(assistant_message)
        
        return ChatMessageResponse(
            message_id=assistant_message.id,
            reply=reply,
            created_at=assistant_message.created_at,
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur IA: {str(e)}")


# ── Upload et gestion des documents ────────────────────────────────────────────

@router.post("/conversations/{thread_id}/upload")
async def upload_document(
    thread_id: str,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Uploader un document (image, PDF, texte) pour une conversation"""
    
    # Vérifier que la conversation existe
    stmt = select(ConversationThread).where(
        ConversationThread.id == thread_id,
        ConversationThread.user_id == current_user.id,
    )
    result = await db.execute(stmt)
    thread = result.scalar_one_or_none()
    
    if not thread:
        raise HTTPException(status_code=404, detail="Conversation non trouvée")
    
    # Valider le type de fichier
    allowed_types = {
        "application/pdf": "pdf",
        "image/jpeg": "jpg",
        "image/png": "png",
        "image/gif": "gif",
        "image/webp": "webp",
        "text/plain": "txt",
    }
    
    content_type = file.content_type or ""
    file_type = allowed_types.get(content_type.lower())
    
    if not file_type:
        raise HTTPException(
            status_code=400,
            detail=f"Type non supporté. Supportés: PDF, Images (JPEG, PNG, GIF, WebP), Texte"
        )
    
    # Lire le fichier
    file_bytes = await file.read()
    file_size = len(file_bytes)
    
    # Valider la taille
    max_size = settings.MAX_FILE_SIZE_MB * 1024 * 1024
    if file_size > max_size:
        raise HTTPException(
            status_code=413,
            detail=f"Fichier trop volumineux (max: {settings.MAX_FILE_SIZE_MB}MB)"
        )
    
    try:
        # Sauvegarder le fichier
        relative_path = save_uploaded_file(file_bytes, file.filename or "document", file_type, current_user.id)
        
        # Traiter le document (extraire texte)
        extracted_text, page_count = process_document_file(file_bytes, file.filename or "document", file_type)
        
        # Créer l'entrée en base
        doc = ChatDocument(
            id=str(uuid.uuid4()),
            thread_id=thread_id,
            user_id=current_user.id,
            filename=relative_path,
            original_filename=file.filename or "document",
            file_type=file_type,
            file_size=file_size,
            extracted_text=extracted_text if extracted_text else None,
            page_count=page_count,
            is_processed=True,
        )
        db.add(doc)
        await db.commit()
        await db.refresh(doc)
        
        return {
            "document_id": doc.id,
            "filename": doc.original_filename,
            "file_type": file_type,
            "file_size": file_size,
            "page_count": page_count,
            "extracted_text_length": len(extracted_text) if extracted_text else 0,
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur upload: {str(e)}")


@router.get("/conversations/{thread_id}/documents", response_model=list[ChatDocumentOut])
async def list_documents(
    thread_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Lister les documents d'une conversation"""
    stmt = (
        select(ChatDocument)
        .where(ChatDocument.thread_id == thread_id)
        .where(ChatDocument.user_id == current_user.id)
        .order_by(desc(ChatDocument.created_at))
    )
    result = await db.execute(stmt)
    documents = result.scalars().all()
    return [ChatDocumentOut.model_validate(d) for d in documents]


