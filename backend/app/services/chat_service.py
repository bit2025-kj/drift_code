import json
import base64
import io
import os
import asyncio
from datetime import datetime
from app.config import settings

try:
    import pypdfium2 as pdfium
except ImportError:
    pdfium = None


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
            if page_text.strip():
                texts.append(page_text)
        
        doc.close()
        return "\n\n".join(texts), page_count
    except Exception as e:
        print(f"❌ Extraction PDF échouée: {e}")
        return "", 0


def extract_text_from_image(image_bytes: bytes) -> str:
    """Extract text from image using OCR if available"""
    # Pour maintenant, on retourne juste les métadonnées
    # Une vraie implémentation utiliserait pytesseract ou Claude Vision
    try:
        from PIL import Image
        img = Image.open(io.BytesIO(image_bytes))
        return f"Image: {img.size[0]}x{img.size[1]} ({img.format})"
    except Exception as e:
        print(f"❌ Extraction image échouée: {e}")
        return ""


def extract_text_from_text_file(text_bytes: bytes) -> str:
    """Extract text from text file"""
    try:
        return text_bytes.decode("utf-8", errors="ignore")
    except Exception as e:
        print(f"❌ Extraction texte échouée: {e}")
        return ""


def save_uploaded_file(file_bytes: bytes, filename: str, file_type: str, user_id: str) -> str:
    """Save uploaded file and return relative path"""
    try:
        # Créer le répertoire s'il n'existe pas
        upload_dir = settings.UPLOAD_DIR
        chat_dir = os.path.join(upload_dir, "chat", user_id)
        os.makedirs(chat_dir, exist_ok=True)
        
        # Générer un nom unique
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        safe_filename = f"{timestamp}_{filename}"
        file_path = os.path.join(chat_dir, safe_filename)
        
        # Sauvegarder le fichier
        with open(file_path, "wb") as f:
            f.write(file_bytes)
        
        # Retourner le chemin relatif
        return os.path.relpath(file_path, upload_dir)
    except Exception as e:
        print(f"❌ Sauvegarde fichier échouée: {e}")
        raise


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


async def generate_context_from_document(
    document_text: str,
    user_question: str,
    matiere_name: str = "Général"
) -> str:
    """Generate AI response based on document context"""
    from mistralai import Mistral
    from app.config import settings
    
    if not settings.MISTRAL_API_KEY:
        raise Exception("Clé API Mistral non configurée")
    
    client = Mistral(api_key=settings.MISTRAL_API_KEY)
    
    prompt = f"""Tu es un assistant éducatif pour Nafa Edu.
L'utilisateur te pose une question sur un document fourni.

DOCUMENT:
---
{document_text[:8000]}
---

QUESTION DE L'UTILISATEUR:
{user_question}

Réponds en fonction du contenu du document. Sois clair, pédagogique et encourage l'apprentissage."""

    try:
        response = await asyncio.to_thread(
            client.chat.complete,
            model="mistral-large-latest",
            messages=[{"role": "user", "content": prompt}],
        )
        return response.choices[0].message.content if response.choices else "Erreur de génération."
    except Exception as e:
        print(f"❌ Génération réponse échouée: {e}")
        raise
