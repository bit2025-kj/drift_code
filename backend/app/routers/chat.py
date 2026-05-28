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

_SYSTEM_PROMPT = """Tu es l’assistant IA officiel de Nafa Edu, une plateforme éducative destinée aux élèves et étudiants du Burkina Faso.

Mission
Tu aides les apprenants à :
- Comprendre leurs cours (maths, sciences, français, histoire-géo, etc.)
- Réviser efficacement leurs examens (BAC, BEPC, concours)
- Résoudre des exercices et problèmes
- Clarifier des notions scolaires ou académiques

Règles de réponse
- Réponds exclusivement en français clair et simple
- Sois pédagogique, structuré et précis
- Adapte toujours tes explications au niveau élève/étudiant
- Utilise des exemples concrets liés au contexte africain quand c’est pertinent

Méthode d’explication
1. Définition simple
2. Explication étape par étape
3. Exemple concret
4. Mini-synthèse

Format Markdown obligatoire
- listes
- **gras**
- blocs code pour formules
"""

# ───────────────────────────── CONVERSATIONS ───────────────────────────── #

@router.post("/conversations", response_model=ConversationThreadOut)
async def create_conversation(
    data: CreateConversationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
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
    stmt = (
        select(ConversationThread)
        .where(ConversationThread.user_id == current_user.id)
        .where(ConversationThread.is_active == True)
        .order_by(desc(ConversationThread.last_message_at))
        .limit(limit)
    )
    result = await db.execute(stmt)
    return [ConversationThreadOut.model_validate(t) for t in result.scalars().all()]


@router.get("/conversations/{thread_id}", response_model=ConversationDetailOut)
async def get_conversation(
    thread_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
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


# ───────────────────────────── CHAT ───────────────────────────── #

@router.post("/conversations/{thread_id}/messages", response_model=ChatMessageResponse)
async def send_message(
    thread_id: str,
    data: SendMessageRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    stmt = select(ConversationThread).where(
        ConversationThread.id == thread_id,
        ConversationThread.user_id == current_user.id,
    )

    result = await db.execute(stmt)
    thread = result.scalar_one_or_none()

    if not thread:
        raise HTTPException(status_code=404, detail="Conversation non trouvée")

    # save user message
    user_message = ConversationMessage(
        id=str(uuid.uuid4()),
        thread_id=thread_id,
        role="user",
        content=data.content,
        document_id=data.document_id,
    )
    db.add(user_message)
    await db.flush()

    # document context
    context_text = ""
    if data.document_id:
        doc_stmt = select(ChatDocument).where(ChatDocument.id == data.document_id)
        doc_result = await db.execute(doc_stmt)
        doc = doc_result.scalar_one_or_none()

        if doc and doc.extracted_text:
            context_text = doc.extracted_text[:2000]

    if not settings.MISTRAL_API_KEY:
        raise HTTPException(status_code=503, detail="Service IA non configuré")

    try:
        msg_stmt = (
            select(ConversationMessage)
            .where(ConversationMessage.thread_id == thread_id)
            .order_by(ConversationMessage.created_at.asc())
            .limit(10)
        )

        result = await db.execute(msg_stmt)
        history = result.scalars().all()

        messages = [
            {
                "role": m.role if m.role in ["user", "assistant"] else "user",
                "content": m.content
            }
            for m in history
        ]

        # inject document as user message
        if context_text:
            messages.insert(0, {
                "role": "user",
                "content": f"DOCUMENT:\n{context_text}"
            })

        client = Mistral(api_key=settings.MISTRAL_API_KEY)

        response = await asyncio.to_thread(
            client.chat.complete,
            model="mistral-large-latest",
            messages=[
                {"role": "system", "content": _SYSTEM_PROMPT},
                *messages,
            ],
        )

        reply = (
            response.choices[0].message.content
            if response.choices else "Erreur génération."
        )

        assistant_message = ConversationMessage(
            id=str(uuid.uuid4()),
            thread_id=thread_id,
            role="assistant",
            content=reply,
        )

        db.add(assistant_message)

        thread.updated_at = datetime.now(timezone.utc)
        thread.last_message_at = datetime.now(timezone.utc)

        await db.commit()
        await db.refresh(assistant_message)

        return ChatMessageResponse(
            message_id=assistant_message.id,
            reply=reply,
            created_at=assistant_message.created_at,
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur IA: {str(e)}")


# ───────────────────────────── UPLOAD ───────────────────────────── #

@router.post("/conversations/{thread_id}/upload")
async def upload_document(
    thread_id: str,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    stmt = select(ConversationThread).where(
        ConversationThread.id == thread_id,
        ConversationThread.user_id == current_user.id,
    )

    result = await db.execute(stmt)
    thread = result.scalar_one_or_none()

    if not thread:
        raise HTTPException(status_code=404, detail="Conversation non trouvée")

    allowed_types = {
        "application/pdf": "pdf",
        "image/jpeg": "jpg",
        "image/png": "png",
        "image/gif": "gif",
        "image/webp": "webp",
        "text/plain": "txt",
    }

    content_type = (file.content_type or "").lower().strip()
    file_type = allowed_types.get(content_type)

    if not file_type:
        raise HTTPException(status_code=400, detail="Format non supporté")

    file_bytes = await file.read()
    file_size = len(file_bytes)

    max_size = settings.MAX_FILE_SIZE_MB * 1024 * 1024
    if file_size > max_size:
        raise HTTPException(status_code=413, detail="Fichier trop volumineux")

    try:
        relative_path = save_uploaded_file(
            file_bytes,
            file.filename or "document",
            file_type,
            current_user.id
        )

        extracted_text, page_count = process_document_file(
            file_bytes,
            file.filename or "document",
            file_type
        )

        doc = ChatDocument(
            id=str(uuid.uuid4()),
            thread_id=thread_id,
            user_id=current_user.id,
            filename=relative_path,
            original_filename=file.filename or "document",
            file_type=file_type,
            file_size=file_size,
            extracted_text=extracted_text or None,
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
            "page_count": page_count,
            "extracted_text_length": len(extracted_text or ""),
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/conversations/{thread_id}/documents", response_model=list[ChatDocumentOut])
async def list_documents(
    thread_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    stmt = (
        select(ChatDocument)
        .where(ChatDocument.thread_id == thread_id)
        .where(ChatDocument.user_id == current_user.id)
        .order_by(desc(ChatDocument.created_at))
    )

    result = await db.execute(stmt)
    return [ChatDocumentOut.model_validate(d) for d in result.scalars().all()]
