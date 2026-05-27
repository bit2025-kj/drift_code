import json
import asyncio
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from app.utils.auth import get_current_user
from app.models.user import User
from app.config import settings
from mistralai.client import Mistral

router = APIRouter(prefix="/ai", tags=["AI"])

_SYSTEM_PROMPT = """Tu es l'assistant IA de Nafa Edu, une plateforme éducative pour les élèves et étudiants du Burkina Faso.
Tu aides avec les cours, examens (BAC, BEPC, concours) et questions académiques.

FORMAT (obligatoire — l'application affiche du Markdown) :
- Réponds en Markdown structuré
- Sois BREF : va droit au but, sans introduction ni conclusion inutile
- Développe uniquement si la question est complexe ou nécessite des étapes détaillées
- Utilise **gras** pour les termes et notions importants
- Listes à puces ou numérotées pour les étapes, énumérations, propriétés
- Tableaux Markdown pour les comparaisons et données structurées
- Formules mathématiques dans des blocs de code (```), exemple :
  ```
  f(x) = ax² + bx + c
  ```
- Titres (## ou ###) uniquement pour les réponses longues avec plusieurs sections
- Blockquotes (> ) pour les définitions importantes ou remarques à retenir

STYLE :
- Français clair et pédagogique, ton encourageant
- Exemples concrets adaptés au contexte burkinabè / africain
- Si hors sujet éducatif : redirige poliment vers les études"""


class ChatMessage(BaseModel):
    role: str  # "user" | "assistant"
    content: str


class ChatRequest(BaseModel):
    messages: list[ChatMessage]
    document_context: str | None = None


class ChatResponse(BaseModel):
    reply: str


class DocumentUploadResponse(BaseModel):
    text: str
    filename: str
    page_count: int
    is_image: bool


def _extract_pdf_text(content: bytes) -> tuple[str, int]:
    """Extract text from PDF bytes. Returns (text, page_count)."""
    try:
        import pypdfium2 as pdfium
        doc = pdfium.PdfDocument(content)
        page_count = len(doc)
        texts = []
        for i in range(min(page_count, 15)):
            page = doc.get_page(i)
            textpage = page.get_textpage()
            text = textpage.get_text_range()
            if text and text.strip():
                texts.append(f"[Page {i + 1}]\n{text.strip()}")
        return '\n\n'.join(texts), page_count
    except Exception as e:
        raise HTTPException(status_code=422, detail=f"Impossible de lire le PDF: {str(e)}")


@router.post("/upload-document", response_model=DocumentUploadResponse)
async def upload_document(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """Upload a PDF or image and extract its text content for AI analysis."""
    content = await file.read()
    filename = file.filename or "document"
    content_type = file.content_type or ""

    is_image = content_type.startswith("image/") or filename.lower().endswith((".jpg", ".jpeg", ".png", ".webp"))
    is_pdf = content_type == "application/pdf" or filename.lower().endswith(".pdf")

    if is_pdf:
        text, page_count = _extract_pdf_text(content)
        if not text.strip():
            text = "[Ce PDF ne contient pas de texte extractible — il est probablement scanné en image.]"
        return DocumentUploadResponse(text=text, filename=filename, page_count=page_count, is_image=False)

    if is_image:
        return DocumentUploadResponse(
            text="[Document image joint]",
            filename=filename,
            page_count=1,
            is_image=True,
        )

    raise HTTPException(status_code=415, detail="Format non supporté. Utilisez un PDF ou une image.")


@router.post("/chat", response_model=ChatResponse)
async def chat(
    body: ChatRequest,
    current_user: User = Depends(get_current_user),
):
    if not settings.MISTRAL_API_KEY:
        raise HTTPException(status_code=503, detail="Service IA non configuré")

    system = _SYSTEM_PROMPT
    if body.document_context:
        system += f"\n\nL'élève t'a partagé le contenu d'un document. Utilise-le pour répondre à ses questions :\n\n---\n{body.document_context[:8000]}\n---"

    try:
        client = Mistral(api_key=settings.MISTRAL_API_KEY)
        response = await asyncio.to_thread(
            client.chat.complete,
            model="mistral-large-latest",
            messages=[
                {"role": "system", "content": system},
                *[{"role": m.role, "content": m.content} for m in body.messages],
            ],
        )
        reply = response.choices[0].message.content if response.choices else "Erreur de génération de réponse."
        return ChatResponse(reply=reply)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur IA: {str(e)}")


@router.post("/chat/stream")
async def chat_stream(
    body: ChatRequest,
    current_user: User = Depends(get_current_user),
):
    if not settings.MISTRAL_API_KEY:
        raise HTTPException(status_code=503, detail="Service IA non configuré")

    system = _SYSTEM_PROMPT
    if body.document_context:
        system += f"\n\nDocument de l'élève :\n\n---\n{body.document_context[:8000]}\n---"

    msgs = [
        {"role": "system", "content": system},
        *[{"role": m.role, "content": m.content} for m in body.messages],
    ]

    def _generate():
        try:
            client = Mistral(api_key=settings.MISTRAL_API_KEY)
            for event in client.chat.stream(model="mistral-large-latest", messages=msgs):
                if not event.data.choices:
                    continue
                raw = event.data.choices[0].delta.content
                if not raw:
                    continue
                text = raw if isinstance(raw, str) else "".join(
                    c.text for c in raw if hasattr(c, "text") and c.text
                )
                if text:
                    yield f"data: {json.dumps({'delta': text})}\n\n"
        except Exception as exc:
            yield f"data: {json.dumps({'error': str(exc)})}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(
        _generate(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )
