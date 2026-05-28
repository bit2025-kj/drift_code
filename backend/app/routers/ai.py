import json
import asyncio
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from app.utils.auth import get_current_user
from app.models.user import User
from app.config import settings
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
        text = await _describe_image_with_ai(content, content_type or "image/jpeg")
        return DocumentUploadResponse(text=text, filename=filename, page_count=1, is_image=True)

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
