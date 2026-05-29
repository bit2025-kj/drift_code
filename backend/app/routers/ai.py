import json
import asyncio
import os
import mimetypes
import httpx
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.utils.auth import get_current_user
from app.models.user import User
from app.models.document import Document
from app.config import settings
from app.utils.storage import local_path_from_url
from mistralai import Mistral

router = APIRouter(prefix="/ai", tags=["AI"])

_SYSTEM_PROMPT = """# SYSTEM PROMPT — NAFA EDU AI

Tu es **Nafa Edu AI**, l’assistant pédagogique intelligent de la plateforme éducative Nafa Edu destinée aux élèves, étudiants et candidats aux concours du Burkina Faso.

Tu aides pour :

* les cours et exercices
* les révisions
* les devoirs
* les examens (CEP, BEPC, BAC)
* les concours et tests
* les explications de notions difficiles
* la méthodologie de travail
* les résumés de cours
* les corrections d’exercices
* les matières scientifiques, littéraires et techniques

Tu dois toujours privilégier :

* la clarté
* la pédagogie
* la lisibilité mobile
* les réponses structurées
* les explications simples et progressives

# RÈGLES DE FORMATAGE (TRÈS IMPORTANT)

L’application affiche du Markdown.

Tu dois TOUJOURS :

* répondre en Markdown propre et bien structuré
* sauter des lignes entre les sections
* éviter les gros blocs de texte
* privilégier les phrases courtes
* rendre les réponses faciles à lire sur téléphone

## Structure recommandée

### Réponse courte

Utiliser :

* listes à puces
* mots-clés en gras
* exemples simples

### Réponse longue

Utiliser :

* titres `##`
* sous-titres `###`
* listes numérotées
* tableaux Markdown si utile
* résumés visuels

# MISE EN FORME

## Concepts importants

Toujours mettre en **gras** :

* définitions
* formules
* dates importantes
* notions clés
* vocabulaire important

Exemple :

* **Photosynthèse**
* **Révolution française**
* **Fonction affine**

---

## Définitions

Utiliser des blockquotes :

> Une cellule est l’unité de base du vivant.

---

## Étapes / Méthodes

Toujours utiliser des listes numérotées :

1. Identifier les données
2. Appliquer la formule
3. Calculer
4. Vérifier le résultat

---

## Comparaisons

Utiliser des tableaux Markdown :

| Élément | Description         |
| ------- | ------------------- |
| Solide  | Forme propre        |
| Liquide | Pas de forme propre |

---

## Mathématiques

Les formules doivent être dans des blocs de code :

```text
a² + b² = c²
```

Pour les calculs détaillés :

```text
2x + 3 = 7
2x = 7 - 3
2x = 4
x = 2
```

---

## Code informatique

Toujours utiliser des blocs de code avec langage :

```python
print("Bonjour")
```

---

# STYLE PÉDAGOGIQUE

Tu dois :

* expliquer simplement
* aller du simple vers le complexe
* utiliser un ton encourageant
* éviter le jargon inutile
* adapter le niveau à l’élève

Tu peux utiliser :

* exemples africains
* contexte burkinabè
* situations concrètes du quotidien
* analogies simples

Exemple :

* agriculture
* marché
* football
* téléphones
* transport
* pluie et saisons

---

# GESTION DES RÉPONSES

## Si la question est simple

Réponse courte et directe.

## Si la question est difficile

Réponse détaillée avec :

* explication
* méthode
* exemple
* résumé final

## Si l’élève se trompe

Corriger avec bienveillance et expliquer pourquoi.

## Si une information est incertaine

Le signaler clairement.

---

# COMPORTEMENT À ÉVITER

Ne jamais :

* écrire de longs paragraphes denses
* utiliser un ton froid
* répondre avec du contenu inutile
* compliquer une explication simple
* inventer des informations
* sortir du cadre éducatif

---

# HORS SUJET

Si la demande n’est pas éducative :

* répondre brièvement
* rediriger poliment vers les études ou l’apprentissage

Exemple :

> Je suis surtout conçu pour aider dans les études, les cours et les révisions scolaires.

---

# OBJECTIF FINAL

Chaque réponse doit :

* aider l’élève à comprendre rapidement
* être agréable à lire sur mobile
* faciliter la mémorisation
* encourager l’apprentissage autonome
* donner envie d’apprendre
"""


_DOCUMENT_RULES = """

# RÈGLES DOCUMENT DE COURS / SUJET (OBLIGATOIRE ET TRÈS STRICT)

Tu dois respecter scrupuleusement les consignes suivantes :
* Tu dois répondre aux questions de l'élève en te basant UNIQUEMENT et EXCLUSIVEMENT sur le contenu extrait du document fourni ci-dessous.
* Interdiction absolue d'inventer des informations, des formules, des exercices, ou des réponses qui ne figurent pas explicitement dans le document.
* Si le contenu du document indique que l'extraction a échoué (par exemple s'il contient "[Le contenu du PDF n'a pas pu être lu automatiquement.]"), tu dois répondre poliment : "Désolé, je ne parviens pas à lire le contenu de ce document actuellement. Veuillez vous assurer que le fichier n'est pas vide ou corrompu." et ne rien imaginer d'autre.
* Si l'information demandée n'est pas présente dans le texte extrait ci-dessous, tu dois obligatoirement répondre : "Je ne le vois pas dans le document." et refuser d'utiliser tes connaissances externes.
* Ne fais jamais d'hypothèses en dehors du texte fourni. Reste extrêmement factuel et concis (3 à 6 lignes maximum pour les explications courantes).
"""

_MAX_TEXT_CHARS = 60000
_MAX_PDF_TEXT_PAGES = 40
_MAX_PDF_OCR_PAGES = 12


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


class AnalyzeDocumentRequest(BaseModel):
    document_id: str


def _extract_pdf_text(content: bytes) -> tuple[str, int]:
    """Extract text from PDF bytes. Returns (text, page_count)."""
    try:
        import pypdfium2 as pdfium
        doc = pdfium.PdfDocument(content)
        page_count = len(doc)
        texts = []
        chars = 0
        for i in range(min(page_count, _MAX_PDF_TEXT_PAGES)):
            page = doc.get_page(i)
            textpage = page.get_textpage()
            text = textpage.get_text_range()
            if text and text.strip():
                block = f"[Page {i + 1}]\n{text.strip()}"
                texts.append(block)
                chars += len(block)
                if chars >= _MAX_TEXT_CHARS:
                    break
        extracted = '\n\n'.join(texts)
        if page_count > _MAX_PDF_TEXT_PAGES:
            extracted += f"\n\n[Note: seules les {_MAX_PDF_TEXT_PAGES} premières pages ont été extraites automatiquement.]"
        return extracted[:_MAX_TEXT_CHARS], page_count
    except Exception as e:
        raise HTTPException(status_code=422, detail=f"Impossible de lire le PDF: {str(e)}")


def _render_pdf_pages_as_images(pdf_bytes: bytes, max_pages: int = _MAX_PDF_OCR_PAGES) -> tuple[list[bytes], int]:
    try:
        import io
        import pypdfium2 as pdfium

        doc = pdfium.PdfDocument(pdf_bytes)
        page_count = len(doc)
        images: list[bytes] = []
        for i in range(min(page_count, max_pages)):
            page = doc[i]
            width = page.get_width()
            scale = 1400.0 / width if width > 0 else 2.0
            bitmap = page.render(scale=scale, rotation=0)
            buf = io.BytesIO()
            bitmap.to_pil().save(buf, format="JPEG", quality=90)
            images.append(buf.getvalue())
        doc.close()
        return images, page_count
    except Exception:
        return [], 0


async def _describe_image_with_ai(image_bytes: bytes, media_type: str) -> str:
    """Use Mistral pixtral to transcribe the full content of an image document."""
    if not settings.MISTRAL_API_KEY:
        return "[Document image joint - analyse IA non disponible]"

    import base64
    valid_types = {"image/jpeg", "image/png", "image/gif", "image/webp"}
    if media_type not in valid_types:
        media_type = "image/jpeg"

    image_b64 = base64.standard_b64encode(image_bytes).decode("utf-8")
    try:
        client = Mistral(api_key=settings.MISTRAL_API_KEY)
        message = await client.chat.complete_async(
            model="pixtral-large-latest",
            messages=[{
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:{media_type};base64,{image_b64}"},
                    },
                    {
                        "type": "text",
                        "text": (
                            "Tu es un professeur expert du système éducatif du Burkina Faso.\n"
                            "Analyse ce document scolaire et retranscris INTÉGRALEMENT son contenu.\n\n"
                            "Extrait tout le texte visible : énoncés, questions, données, formules, tableaux, "
                            "schémas (décrits en détail). Si c'est un sujet d'examen, liste tous les exercices "
                            "et questions avec leurs numéros. Préserve la structure du document autant que possible. "
                            "N'omets aucune information visible."
                        ),
                    },
                ],
            }],
        )
        return message.choices[0].message.content
    except Exception as e:
        print(f"❌ Analyse image document échouée: {e}")
        return "[Document image joint - le contenu n'a pas pu être extrait automatiquement]"


async def _ocr_pdf_with_ai(pdf_bytes: bytes) -> tuple[str, int]:
    images, page_count = _render_pdf_pages_as_images(pdf_bytes)
    if not images:
        return "", page_count or 1

    pages = []
    for index, image in enumerate(images, start=1):
        text = await _describe_image_with_ai(image, "image/jpeg")
        if text.strip():
            pages.append(f"[Page {index}]\n{text.strip()}")

    extracted = "\n\n".join(pages)
    if page_count > len(images):
        extracted += f"\n\n[Note: seules les {len(images)} premières pages images ont pu être lues automatiquement.]"
    return extracted[:_MAX_TEXT_CHARS], page_count


async def _read_document_bytes(file_url: str) -> tuple[bytes, str, str]:
    clean_url = file_url.split("?", 1)[0]
    filename = os.path.basename(clean_url) or "document"

    if file_url.startswith("http://") or file_url.startswith("https://"):
        try:
            async with httpx.AsyncClient(timeout=60, follow_redirects=True) as client:
                response = await client.get(file_url)
                response.raise_for_status()
            content_type = response.headers.get("content-type", "").split(";", 1)[0]
            return response.content, filename, content_type
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=404, detail=f"Impossible de lire le fichier distant: {exc}")

    if file_url.startswith("/uploads/"):
        local_path = local_path_from_url(file_url)
    else:
        local_path = os.path.join(settings.UPLOAD_DIR, "documents", filename)

    if not os.path.exists(local_path):
        raise HTTPException(status_code=404, detail="Fichier introuvable sur le serveur")

    with open(local_path, "rb") as f:
        content = f.read()
    return content, filename, mimetypes.guess_type(filename)[0] or ""


async def _extract_document_content(content: bytes, filename: str, content_type: str) -> DocumentUploadResponse:
    lower = filename.lower().split("?", 1)[0]
    is_image = content_type.startswith("image/") or lower.endswith((".jpg", ".jpeg", ".png", ".webp", ".gif"))
    is_pdf = content_type == "application/pdf" or lower.endswith(".pdf")

    if is_image:
        text = await _describe_image_with_ai(content, content_type or "image/jpeg")
        return DocumentUploadResponse(text=text, filename=filename, page_count=1, is_image=True)

    if is_pdf:
        try:
            text, page_count = _extract_pdf_text(content)
        except HTTPException:
            text, page_count = "", 1

        if not text.strip():
            text, page_count = await _ocr_pdf_with_ai(content)
        if not text.strip():
            text = "[Le contenu du PDF n'a pas pu être lu automatiquement.]"
        return DocumentUploadResponse(text=text, filename=filename, page_count=page_count, is_image=False)

    raise HTTPException(status_code=415, detail="Format non supporté. Utilisez un PDF ou une image.")


@router.post("/upload-document", response_model=DocumentUploadResponse)
async def upload_document(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """Upload a PDF or image and extract its text content for AI analysis."""
    content = await file.read()
    filename = file.filename or "document"
    content_type = file.content_type or ""

    return await _extract_document_content(content, filename, content_type)


@router.post("/analyze-document", response_model=DocumentUploadResponse)
async def analyze_document(
    body: AnalyzeDocumentRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Extract text content from a stored document (by document_id) for AI analysis."""
    result = await db.execute(select(Document).where(Document.id == body.document_id))
    doc = result.scalar_one_or_none()
    if not doc or not doc.file_url:
        raise HTTPException(status_code=404, detail="Document introuvable")

    content, filename, content_type = await _read_document_bytes(doc.file_url)
    return await _extract_document_content(content, filename, content_type)


@router.post("/chat", response_model=ChatResponse)
async def chat(
    body: ChatRequest,
    current_user: User = Depends(get_current_user),
):
    if not settings.MISTRAL_API_KEY:
        raise HTTPException(status_code=503, detail="Service IA non configuré")

    system = _SYSTEM_PROMPT
    if body.document_context:
        system += (
            _DOCUMENT_RULES
            + "\n\nCONTENU EXTRAIT DU FICHIER (pas des métadonnées) :\n\n---\n"
            + body.document_context[:_MAX_TEXT_CHARS]
            + "\n---"
        )

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
        system += (
            _DOCUMENT_RULES
            + "\n\nCONTENU EXTRAIT DU FICHIER (pas des métadonnées) :\n\n---\n"
            + body.document_context[:_MAX_TEXT_CHARS]
            + "\n---"
        )

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
