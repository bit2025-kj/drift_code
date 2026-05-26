import json
import base64
import io
import asyncio
from app.config import settings

FALLBACK_QUESTIONS = {
    "Mathématiques": [
        {
            "content": "Quelle est la solution de l'équation 2x + 6 = 0 ?",
            "options": {"A": "x = -3", "B": "x = 3", "C": "x = -6", "D": "x = 6"},
            "correct_answer": "A",
            "explanation": "2x + 6 = 0 → 2x = -6 → x = -3",
        },
        {
            "content": "Le discriminant d'un trinôme ax² + bx + c est :",
            "options": {"A": "b² - 4ac", "B": "b² + 4ac", "C": "4ac - b²", "D": "2b - ac"},
            "correct_answer": "A",
            "explanation": "Le discriminant Δ = b² - 4ac permet de déterminer le nombre de racines.",
        },
        {
            "content": "Quelle est la dérivée de f(x) = x³ - 2x² + 5 ?",
            "options": {"A": "3x² - 4x", "B": "3x² - 2x", "C": "x² - 4x", "D": "3x - 4"},
            "correct_answer": "A",
            "explanation": "f'(x) = 3x² - 4x en appliquant les règles de dérivation.",
        },
        {
            "content": "Combien vaut sin(30°) ?",
            "options": {"A": "1/2", "B": "√2/2", "C": "√3/2", "D": "1"},
            "correct_answer": "A",
            "explanation": "sin(30°) = 1/2 est une valeur à connaître par cœur.",
        },
        {
            "content": "Quelle est la forme développée de (a+b)² ?",
            "options": {"A": "a² + 2ab + b²", "B": "a² + b²", "C": "a² - 2ab + b²", "D": "2a + 2b"},
            "correct_answer": "A",
            "explanation": "(a+b)² = a² + 2ab + b² par développement.",
        },
    ],
    "Physique-Chimie": [
        {
            "content": "Quelle est la valeur de la constante de Planck ?",
            "options": {"A": "6,626 × 10⁻³⁴ J·s", "B": "9,11 × 10⁻³¹ kg", "C": "1,6 × 10⁻¹⁹ C", "D": "3 × 10⁸ m/s"},
            "correct_answer": "A",
            "explanation": "La constante de Planck h = 6,626 × 10⁻³⁴ J·s est fondamentale en mécanique quantique.",
        },
        {
            "content": "Quelle est la vitesse de la lumière dans le vide ?",
            "options": {"A": "3 × 10⁸ m/s", "B": "3 × 10⁶ m/s", "C": "3 × 10¹⁰ m/s", "D": "3 × 10⁴ m/s"},
            "correct_answer": "A",
            "explanation": "c ≈ 3 × 10⁸ m/s dans le vide.",
        },
        {
            "content": "Quel est le pH d'une solution neutre à 25°C ?",
            "options": {"A": "7", "B": "0", "C": "14", "D": "6"},
            "correct_answer": "A",
            "explanation": "À 25°C, une solution neutre a pH = 7.",
        },
    ],
    "Français": [
        {
            "content": "Quelle figure de style est utilisée dans : 'La vie est un long fleuve tranquille' ?",
            "options": {"A": "Métaphore", "B": "Comparaison", "C": "Hyperbole", "D": "Personnification"},
            "correct_answer": "A",
            "explanation": "C'est une métaphore car elle compare la vie à un fleuve sans utiliser 'comme' ou 'tel'.",
        },
        {
            "content": "Quel est l'auteur des Misérables ?",
            "options": {"A": "Victor Hugo", "B": "Émile Zola", "C": "Honoré de Balzac", "D": "Gustave Flaubert"},
            "correct_answer": "A",
            "explanation": "Les Misérables (1862) est l'œuvre de Victor Hugo.",
        },
    ],
    "Histoire-Géographie": [
        {
            "content": "En quelle année le Burkina Faso a-t-il accédé à l'indépendance ?",
            "options": {"A": "1960", "B": "1958", "C": "1962", "D": "1945"},
            "correct_answer": "A",
            "explanation": "La Haute-Volta (devenue Burkina Faso) a obtenu son indépendance le 5 août 1960.",
        },
        {
            "content": "Quelle est la capitale du Burkina Faso ?",
            "options": {"A": "Ouagadougou", "B": "Bobo-Dioulasso", "C": "Koudougou", "D": "Banfora"},
            "correct_answer": "A",
            "explanation": "Ouagadougou est la capitale et la plus grande ville du Burkina Faso.",
        },
    ],
}

_JSON_SCHEMA = '[{"content": "Question ?", "options": {"A": "opt A", "B": "opt B", "C": "opt C", "D": "opt D"}, "correct_answer": "A", "explanation": "Explication courte"}]'


def _parse_ai_response(text: str) -> list[dict]:
    text = text.strip()
    if text.startswith("```"):
        parts = text.split("```")
        text = parts[1] if len(parts) > 1 else text
        if text.startswith("json"):
            text = text[4:]
    return json.loads(text.strip())


async def generate_quiz_with_ai(
    matiere_name: str,
    difficulty: str,
    question_count: int,
    topic: str | None = None,
) -> list[dict]:
    if not settings.MISTRAL_API_KEY:
        raise Exception("Clé API Mistral non configurée")

    try:
        from mistralai.client import Mistral
        client = Mistral(api_key=settings.MISTRAL_API_KEY)

        topic_context = f"sur le thème '{topic}'" if topic else ""
        prompt = f"""Tu es un professeur expert du système éducatif du Burkina Faso.
Génère exactement {question_count} questions QCM de niveau {difficulty} en {matiere_name} {topic_context}.

Chaque question doit avoir 4 options (A, B, C, D) avec une seule bonne réponse.
Le contexte doit être adapté aux élèves burkinabè.

Réponds UNIQUEMENT avec un JSON valide dans ce format exact:
{_JSON_SCHEMA}"""

        message = await asyncio.to_thread(
            client.chat.complete,
            model="mistral-large-latest",
            messages=[{"role": "user", "content": prompt}],
        )
        return _parse_ai_response(message.choices[0].message.content)

    except Exception as e:
        print(f"❌ Génération IA échouée: {e}")
        raise


async def generate_quiz_from_content(
    content: str,
    matiere_name: str,
    difficulty: str,
    question_count: int,
) -> list[dict]:
    """Generate quiz from text content extracted from a PDF or typed course."""
    if not settings.MISTRAL_API_KEY:
        raise Exception("Clé API Mistral non configurée")

    try:
        from mistralai.client import Mistral
        client = Mistral(api_key=settings.MISTRAL_API_KEY)

        prompt = f"""Tu es un professeur expert du système éducatif du Burkina Faso.
Voici le contenu d'un cours :
---
{content[:8000]}
---
Génère exactement {question_count} questions QCM de niveau {difficulty} en {matiere_name} basées sur ce contenu.
Chaque question doit avoir 4 options (A, B, C, D) avec une seule bonne réponse.
Les questions doivent être directement tirées du contenu fourni.

Réponds UNIQUEMENT avec un JSON valide dans ce format exact:
{_JSON_SCHEMA}"""

        message = await asyncio.to_thread(
            client.chat.complete,
            model="mistral-large-latest",
            messages=[{"role": "user", "content": prompt}],
        )
        return _parse_ai_response(message.choices[0].message.content)

    except Exception as e:
        print(f"❌ Génération depuis contenu échouée: {e}")
        raise


async def generate_quiz_from_image(
    image_bytes: bytes,
    media_type: str,
    matiere_name: str,
    difficulty: str,
    question_count: int,
) -> list[dict]:
    """Generate quiz from an image (photo of notes, scanned course page)."""
    if not settings.MISTRAL_API_KEY:
        raise Exception("Clé API Mistral non configurée")

    valid_types = {"image/jpeg", "image/png", "image/gif", "image/webp"}
    if media_type not in valid_types:
        media_type = "image/jpeg"

    try:
        from mistralai.client import Mistral
        client = Mistral(api_key=settings.MISTRAL_API_KEY)

        image_b64 = base64.standard_b64encode(image_bytes).decode("utf-8")

        message = await asyncio.to_thread(
            client.chat.complete,
            model="mistral-large-latest",
            messages=[{
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": f"data:{media_type};base64,{image_b64}",
                    },
                    {
                        "type": "text",
                        "text": f"""Tu es un professeur expert du système éducatif du Burkina Faso.
Analyse ce document de cours et génère exactement {question_count} questions QCM de niveau {difficulty} en {matiere_name}.
Chaque question doit avoir 4 options (A, B, C, D) avec une seule bonne réponse.
Base les questions sur le contenu visible dans l'image.

Réponds UNIQUEMENT avec un JSON valide dans ce format exact:
{_JSON_SCHEMA}""",
                    },
                ],
            }],
        )
        return _parse_ai_response(message.choices[0].message.content)

    except Exception as e:
        print(f"❌ Génération depuis image échouée: {e}")
        raise


def extract_text_from_pdf(pdf_bytes: bytes) -> str:
    """Extract text from PDF using pypdfium2 (up to 5 pages)."""
    try:
        import pypdfium2 as pdfium
        doc = pdfium.PdfDocument(pdf_bytes)
        texts = []
        for i in range(min(len(doc), 5)):
            page = doc[i]
            textpage = page.get_textpage()
            page_text = textpage.get_text_range()
            if page_text.strip():
                texts.append(page_text)
        doc.close()
        return "\n\n".join(texts)
    except Exception as e:
        print(f"Extraction texte PDF échouée: {e}")
        return ""


def render_pdf_page_as_image(pdf_bytes: bytes) -> bytes | None:
    """Render first PDF page as JPEG bytes for vision AI (fallback for scanned PDFs)."""
    try:
        import pypdfium2 as pdfium
        doc = pdfium.PdfDocument(pdf_bytes)
        page = doc[0]
        bitmap = page.render(scale=1.5, rotation=0)
        pil_image = bitmap.to_pil()
        buf = io.BytesIO()
        pil_image.save(buf, format="JPEG", quality=80)
        doc.close()
        return buf.getvalue()
    except Exception as e:
        print(f"Rendu PDF en image échoué: {e}")
        return None


def _get_fallback_questions(matiere_name: str, count: int) -> list[dict]:
    for key in FALLBACK_QUESTIONS:
        if key.lower() in matiere_name.lower() or matiere_name.lower() in key.lower():
            questions = FALLBACK_QUESTIONS[key]
            while len(questions) < count:
                questions = questions + questions
            return questions[:count]
    return (FALLBACK_QUESTIONS["Mathématiques"] * 10)[:count]
