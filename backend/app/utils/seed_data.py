"""
Données de référence du système éducatif du Burkina Faso.
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models import (
    EducationLevel, Classe, Matiere, TypeExamen,
    Badge, ForumCategory
)

LEVELS = [
    {"name": "Primaire", "slug": "primaire", "order": 1, "icon": "school", "color": "#4CAF50"},
    {"name": "Collège", "slug": "college", "order": 2, "icon": "menu_book", "color": "#2196F3"},
    {"name": "Lycée", "slug": "lycee", "order": 3, "icon": "auto_stories", "color": "#FF9800"},
    {"name": "Université", "slug": "universite", "order": 4, "icon": "account_balance", "color": "#9C27B0"},
    {"name": "Concours", "slug": "concours", "order": 5, "icon": "emoji_events", "color": "#F44336"},
]

CLASSES = {
    "primaire": [
        {"name": "CP1", "slug": "cp1", "order": 1},
        {"name": "CP2", "slug": "cp2", "order": 2},
        {"name": "CE1", "slug": "ce1", "order": 3},
        {"name": "CE2", "slug": "ce2", "order": 4},
        {"name": "CM1", "slug": "cm1", "order": 5},
        {"name": "CM2", "slug": "cm2", "order": 6},
    ],
    "college": [
        {"name": "6ème", "slug": "6eme", "order": 1},
        {"name": "5ème", "slug": "5eme", "order": 2},
        {"name": "4ème", "slug": "4eme", "order": 3},
        {"name": "3ème", "slug": "3eme", "order": 4},
    ],
    "lycee": [
        {"name": "Seconde", "slug": "seconde", "order": 1},
        {"name": "Première A", "slug": "premiere-a", "order": 2},
        {"name": "Première C", "slug": "premiere-c", "order": 3},
        {"name": "Première D", "slug": "premiere-d", "order": 4},
        {"name": "Terminale A1", "slug": "terminale-a1", "order": 5},
        {"name": "Terminale A2", "slug": "terminale-a2", "order": 6},
        {"name": "Terminale B", "slug": "terminale-b", "order": 7},
        {"name": "Terminale C", "slug": "terminale-c", "order": 8},
        {"name": "Terminale D", "slug": "terminale-d", "order": 9},
        {"name": "Terminale E", "slug": "terminale-e", "order": 10},
    ],
    "universite": [
        {"name": "Licence 1", "slug": "licence-1", "order": 1},
        {"name": "Licence 2", "slug": "licence-2", "order": 2},
        {"name": "Licence 3", "slug": "licence-3", "order": 3},
        {"name": "Master 1", "slug": "master-1", "order": 4},
        {"name": "Master 2", "slug": "master-2", "order": 5},
    ],
    "concours": [
        {"name": "Général", "slug": "general", "order": 1},
    ],
}

MATIERES = [
    {"name": "Mathématiques", "slug": "mathematiques", "icon": "calculate", "color": "#2196F3"},
    {"name": "Physique-Chimie", "slug": "physique-chimie", "icon": "science", "color": "#FF5722"},
    {"name": "Sciences de la Vie et de la Terre (SVT)", "slug": "svt", "icon": "eco", "color": "#4CAF50"},
    {"name": "Français", "slug": "francais", "icon": "menu_book", "color": "#9C27B0"},
    {"name": "Philosophie", "slug": "philosophie", "icon": "psychology", "color": "#607D8B"},
    {"name": "Histoire-Géographie", "slug": "histoire-geo", "icon": "public", "color": "#795548"},
    {"name": "Anglais", "slug": "anglais", "icon": "language", "color": "#00BCD4"},
    {"name": "Espagnol", "slug": "espagnol", "icon": "language", "color": "#FF9800"},
    {"name": "Allemand", "slug": "allemand", "icon": "language", "color": "#FFEB3B"},
    {"name": "Éducation Civique", "slug": "education-civique", "icon": "gavel", "color": "#3F51B5"},
    {"name": "Sciences Économiques", "slug": "sciences-eco", "icon": "trending_up", "color": "#009688"},
    {"name": "Technologies", "slug": "technologies", "icon": "engineering", "color": "#FF6F00"},
    {"name": "Sciences d'Éveil", "slug": "sciences-eveil", "icon": "lightbulb", "color": "#FFC107"},
    {"name": "Éducation Physique et Sportive", "slug": "eps", "icon": "sports", "color": "#8BC34A"},
    {"name": "Informatique", "slug": "informatique", "icon": "computer", "color": "#1E88E5"},
    {"name": "Culture Générale", "slug": "culture-generale", "icon": "emoji_objects", "color": "#E91E63"},
    {"name": "Droit", "slug": "droit", "icon": "balance", "color": "#5C6BC0"},
    {"name": "Économie Générale", "slug": "economie", "icon": "account_balance", "color": "#26A69A"},
]

TYPES_EXAMENS = {
    "primaire": [
        {"name": "Devoir", "slug": "devoir", "is_national": False, "order": 1},
        {"name": "Examen Blanc", "slug": "examen-blanc-primaire", "is_national": False, "order": 2},
        {"name": "CEP (Certificat d'Études Primaires)", "slug": "cep", "is_national": True, "order": 3},
        {"name": "Test d'entrée en 6ème", "slug": "test-entree-6eme", "is_national": True, "order": 4},
    ],
    "college": [
        {"name": "Devoir", "slug": "devoir-college", "is_national": False, "order": 1},
        {"name": "Examen Blanc", "slug": "examen-blanc-college", "is_national": False, "order": 2},
        {"name": "BEPC (Brevet d'Études du Premier Cycle)", "slug": "bepc", "is_national": True, "order": 3},
        {"name": "Test d'entrée en Seconde", "slug": "test-entree-seconde", "is_national": True, "order": 4},
    ],
    "lycee": [
        {"name": "Devoir", "slug": "devoir-lycee", "is_national": False, "order": 1},
        {"name": "Examen Blanc", "slug": "examen-blanc-lycee", "is_national": False, "order": 2},
        {"name": "BAC série A1 (Lettres-Philosophie)", "slug": "bac-a1", "is_national": True, "order": 3},
        {"name": "BAC série A2 (Lettres-Langues)", "slug": "bac-a2", "is_national": True, "order": 4},
        {"name": "BAC série B (Sciences Économiques)", "slug": "bac-b", "is_national": True, "order": 5},
        {"name": "BAC série C (Math-Physique)", "slug": "bac-c", "is_national": True, "order": 6},
        {"name": "BAC série D (Sciences de la Vie)", "slug": "bac-d", "is_national": True, "order": 7},
        {"name": "BAC série E (Technologie)", "slug": "bac-e", "is_national": True, "order": 8},
    ],
    "universite": [
        {"name": "Partiel", "slug": "partiel", "is_national": False, "order": 1},
        {"name": "Examen Final", "slug": "examen-final", "is_national": False, "order": 2},
        {"name": "Rattrapage", "slug": "rattrapage", "is_national": False, "order": 3},
    ],
    "concours": [
        {"name": "ENAREF (Régies Financières)", "slug": "enaref", "is_national": True, "order": 1},
        {"name": "ENAM (Administration & Magistrature)", "slug": "enam", "is_national": True, "order": 2},
        {"name": "École de Police Nationale", "slug": "police-nationale", "is_national": True, "order": 3},
        {"name": "École Nationale de Gendarmerie", "slug": "gendarmerie", "is_national": True, "order": 4},
        {"name": "Armée de Terre", "slug": "armee-de-terre", "is_national": True, "order": 5},
        {"name": "Douanes (DGDDI)", "slug": "douanes", "is_national": True, "order": 6},
        {"name": "Trésor Public (DGTCP)", "slug": "tresor-public", "is_national": True, "order": 7},
        {"name": "BUMIGEB (Mines & Géologie)", "slug": "bumigeb", "is_national": True, "order": 8},
        {"name": "INSD (Statistiques)", "slug": "insd", "is_national": True, "order": 9},
        {"name": "FONER (Éducation & Recherche)", "slug": "foner", "is_national": True, "order": 10},
        {"name": "Concours de Médecine", "slug": "medecine", "is_national": True, "order": 11},
        {"name": "INFSS (Santé)", "slug": "infss", "is_national": True, "order": 12},
        {"name": "IBAM (Banque)", "slug": "ibam", "is_national": True, "order": 13},
        {"name": "ONATEL (Télécoms)", "slug": "onatel", "is_national": True, "order": 14},
        {"name": "SONABHY (Hydrocarbures)", "slug": "sonabhy", "is_national": True, "order": 15},
        {"name": "Culture Générale", "slug": "culture-generale-concours", "is_national": False, "order": 16},
    ],
}

BADGES = [
    {"name": "Premier Pas", "description": "Télécharger son premier sujet", "icon": "🎯",
     "color": "#4CAF50", "condition_type": "downloads", "condition_value": 1, "points_reward": 50},
    {"name": "Apprenant Actif", "description": "Télécharger 10 sujets", "icon": "📚",
     "color": "#2196F3", "condition_type": "downloads", "condition_value": 10, "points_reward": 100},
    {"name": "Bibliothèque", "description": "Télécharger 50 sujets", "icon": "🏛️",
     "color": "#9C27B0", "condition_type": "downloads", "condition_value": 50, "points_reward": 300},
    {"name": "Quiz Master", "description": "Obtenir 100% à un quiz", "icon": "🏆",
     "color": "#FF9800", "condition_type": "quiz_score", "condition_value": 100, "points_reward": 200},
    {"name": "En Feu 🔥", "description": "7 jours de révision consécutifs", "icon": "🔥",
     "color": "#F44336", "condition_type": "quiz_streak", "condition_value": 7, "points_reward": 150},
    {"name": "Régulier", "description": "30 jours actifs", "icon": "⭐",
     "color": "#FFC107", "condition_type": "active_days", "condition_value": 30, "points_reward": 250},
    {"name": "Contributeur", "description": "Poster 10 messages sur le forum", "icon": "💬",
     "color": "#00BCD4", "condition_type": "forum_posts", "condition_value": 10, "points_reward": 100},
    {"name": "Explorateur", "description": "Consulter 5 matières différentes", "icon": "🔭",
     "color": "#607D8B", "condition_type": "subjects_explored", "condition_value": 5, "points_reward": 80},
    {"name": "Champion BF", "description": "Atteindre le Top 10 du classement", "icon": "🇧🇫",
     "color": "#EF2B2D", "condition_type": "rank", "condition_value": 10, "points_reward": 500},
]

FORUM_CATEGORIES = [
    {"name": "Questions & Réponses", "slug": "questions", "icon": "help_outline", "color": "#2196F3",
     "description": "Pose tes questions, obtiens des réponses de la communauté", "order": 1},
    {"name": "Cours & Révisions", "slug": "cours-revisions", "icon": "menu_book", "color": "#4CAF50",
     "description": "Partagez vos résumés et notes de cours", "order": 2},
    {"name": "Examens & Concours", "slug": "examens", "icon": "assignment", "color": "#FF9800",
     "description": "Discussions autour du BAC, BEPC et concours nationaux", "order": 3},
    {"name": "Orientation", "slug": "orientation", "icon": "explore", "color": "#9C27B0",
     "description": "Conseils d'orientation scolaire et professionnelle", "order": 4},
    {"name": "Annonces", "slug": "annonces", "icon": "campaign", "color": "#F44336",
     "description": "Actualités éducatives au Burkina Faso", "order": 5},
]


async def seed_database(db: AsyncSession):
    # Fonction idempotente : vérifie chaque enregistrement individuellement

    # ── Niveaux ──────────────────────────────────────────────────────────────
    level_objects = {}
    for level_data in LEVELS:
        res = await db.execute(select(EducationLevel).where(EducationLevel.slug == level_data["slug"]))
        level = res.scalar_one_or_none()
        if not level:
            level = EducationLevel(**level_data)
            db.add(level)
            await db.flush()
        level_objects[level_data["slug"]] = level

    # ── Classes ──────────────────────────────────────────────────────────────
    for level_slug, classes in CLASSES.items():
        level = level_objects[level_slug]
        for cls_data in classes:
            res = await db.execute(select(Classe).where(Classe.slug == cls_data["slug"]))
            if not res.scalar_one_or_none():
                db.add(Classe(level_id=level.id, **cls_data))
    await db.flush()

    # ── Matières ─────────────────────────────────────────────────────────────
    for mat_data in MATIERES:
        res = await db.execute(select(Matiere).where(Matiere.slug == mat_data["slug"]))
        if not res.scalar_one_or_none():
            db.add(Matiere(**mat_data))
    await db.flush()

    # ── Types d'examens ───────────────────────────────────────────────────────
    for level_slug, types in TYPES_EXAMENS.items():
        level = level_objects[level_slug]
        for type_data in types:
            res = await db.execute(select(TypeExamen).where(TypeExamen.slug == type_data["slug"]))
            if not res.scalar_one_or_none():
                db.add(TypeExamen(level_id=level.id, **type_data))

    # ── Badges ────────────────────────────────────────────────────────────────
    for badge_data in BADGES:
        res = await db.execute(select(Badge).where(Badge.name == badge_data["name"]))
        if not res.scalar_one_or_none():
            db.add(Badge(**badge_data))

    # ── Catégories forum ──────────────────────────────────────────────────────
    for cat_data in FORUM_CATEGORIES:
        res = await db.execute(select(ForumCategory).where(ForumCategory.slug == cat_data["slug"]))
        if not res.scalar_one_or_none():
            db.add(ForumCategory(**cat_data))

    await db.commit()
    print("Seed Burkina Faso termine (donnees existantes conservees)")
