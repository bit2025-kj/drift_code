import io
import asyncio
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from pydantic import BaseModel
from app.utils.auth import get_current_user
from app.models.user import User
from app.config import settings
from mistralai.client import Mistral

router = APIRouter(prefix="/ai", tags=["AI"])

_SYSTEM_PROMPT = """Tu es l'assistant IA de Nafa Edu, une plateforme éducative pour les élèves et étudiants du Burkina Faso.
Tu aides les élèves à comprendre leurs cours, préparer leurs examens (BAC, BEPC, concours), et répondre à leurs questions académiques.
Tu réponds en français, de façon claire, pédagogique et encourageante.
Quand tu expliques un concept, donne des exemples concrets adaptés au contexte africain.
Sois concis mais complet. Si une question est hors sujet éducatif, redirige poliment vers les études."""


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
