import json
import asyncio
import io
import os
from datetime import datetime
from app.config import settings

try:
    import pypdfium2 as pdfium
except ImportError:
    pdfium = None


# ─────────────────────────────────────────────
# PDF EXTRACTION
# ─────────────────────────────────────────────
def extract_text_from_pdf(pdf_bytes: bytes, max_pages: int = 10) -> tuple[str, int]:
    """Extract text from PDF and return (text, page_count)"""

    if not pdfium:
        return "", 0

    try:
        doc = pdfium.PdfDocument(pdf_bytes)
        texts = []
        page_count = len(doc)

        for i in range(min(page_count, max_pages)):
            page = doc[i]
            textpage = page.get_textpage()

            page_text = textpage.get_text_range()

            if page_text and page_text.strip():
                texts.append(page_text.strip())

            # cleanup mémoire
            textpage.close()
            page.close()

        doc.close()

        return "\n\n".join(texts), page_count

    except Exception as e:
        print(f"❌ Extraction PDF échouée: {e}")
        return "", 0


# ─────────────────────────────────────────────
# IMAGE EXTRACTION (placeholder sans OCR)
# ─────────────────────────────────────────────
def extract_text_from_image(image_bytes: bytes) -> str:
    """Extract text from image (OCR placeholder)"""

    try:
        from PIL import Image

        img = Image.open(io.BytesIO(image_bytes))

        # IMPORTANT: pas de bruit inutile dans le prompt
        # Sans OCR réel → on ne retourne rien
        return ""

    except Exception as e:
        print(f"❌ Extraction image échouée: {e}")
        return ""


# ─────────────────────────────────────────────
# TEXT FILE
# ─────────────────────────────────────────────
def extract_text_from_text_file(text_bytes: bytes) -> str:
    try:
        return text_bytes.decode("utf-8", errors="ignore")
    except Exception as e:
        print(f"❌ Extraction texte échouée: {e}")
        return ""


# ─────────────────────────────────────────────
# SAVE FILE
# ─────────────────────────────────────────────
def save_uploaded_file(file_bytes: bytes, filename: str, file_type: str, user_id: str) -> str:
    """Save uploaded file and return relative path"""

    try:
        upload_dir = settings.UPLOAD_DIR
        chat_dir = os.path.join(upload_dir, "chat", user_id)

        os.makedirs(chat_dir, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        safe_filename = f"{timestamp}_{filename}"

        file_path = os.path.join(chat_dir, safe_filename)

        with open(file_path, "wb") as f:
            f.write(file_bytes)

        # chemin stable (évite relpath fragile)
        return os.path.join("chat", user_id, safe_filename)

    except Exception as e:
        print(f"❌ Sauvegarde fichier échouée: {e}")
        raise


# ─────────────────────────────────────────────
# DOCUMENT PROCESSING
# ─────────────────────────────────────────────
def process_document_file(file_bytes: bytes, filename: str, file_type: str) -> tuple[str, int | None]:
    """Process document and extract text"""

    extracted_text = ""
    page_count = None

    if file_type == "pdf":
        extracted_text, page_count = extract_text_from_pdf(file_bytes)

    elif file_type in ["jpg", "jpeg", "png", "gif", "webp"]:
        extracted_text = extract_text_from_image(file_bytes)

    elif file_type in ["txt", "text"]:
        extracted_text = extract_text_from_text_file(file_bytes)

    return extracted_text, page_count


# ─────────────────────────────────────────────
# MISTRAL CONTEXT GENERATION
# ─────────────────────────────────────────────
async def generate_context_from_document(
    document_text: str,
    user_question: str,
    matiere_name: str = "Général"
) -> str:

    from mistralai import Mistral

    if not settings.MISTRAL_API_KEY:
        raise Exception("Clé API Mistral non configurée")

    client = Mistral(api_key=settings.MISTRAL_API_KEY)

    # limitation anti-token explosion
    document_text = document_text[:6000]

    prompt = f"""
Tu es un assistant pédagogique Nafa Edu.

DOCUMENT:
{document_text}

QUESTION:
{user_question}

Règles:
- Réponds uniquement avec les informations du document
- Si l'information n'existe pas dans le document, dis-le clairement
- Sois simple, clair et pédagogique
"""

    try:
        response = await asyncio.to_thread(
            client.chat.complete,
            model="mistral-large-latest",
            messages=[
                {"role": "user", "content": prompt}
            ],
        )

        if response.choices and len(response.choices) > 0:
            return response.choices[0].message.content

        return "Erreur: réponse vide du modèle."

    except Exception as e:
        print(f"❌ Génération réponse échouée: {e}")
        raise
