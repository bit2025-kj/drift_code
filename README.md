# Nafa Edu — Révise. Apprends. Réussis.

Plateforme éducative mobile intelligente pour le Burkina Faso.

## Stack Technique
- **Mobile** : Flutter + Riverpod + Dio
- **Backend** : FastAPI + SQLAlchemy (async)
- **Base de données** : PostgreSQL 16
- **Cache** : Redis 7
- **IA** : Anthropic Claude (génération de quiz)

## Structure du Projet
```
drift_code/
├── backend/          # API FastAPI
│   ├── app/
│   │   ├── models/   # Modèles SQLAlchemy
│   │   ├── schemas/  # Schemas Pydantic
│   │   ├── routers/  # Routes API
│   │   ├── services/ # Logique métier
│   │   └── utils/    # Auth, seed data BF
│   ├── docker-compose.yml
│   └── requirements.txt
└── frontend/         # App Flutter
    └── lib/
        ├── screens/  # 6 écrans + downloads
        ├── providers/ # State Riverpod
        ├── models/    # Modèles Dart
        ├── services/  # Sync, download manager
        ├── core/      # API client, DB locale
        └── config/    # Thème, constantes BF
```

## Démarrage Rapide

### Backend
```bash
cd backend
cp .env.example .env
# Éditer .env : ajouter ANTHROPIC_API_KEY
docker-compose up -d db redis
pip install -r requirements.txt
uvicorn app.main:app --reload
# API disponible sur http://localhost:8000
# Docs : http://localhost:8000/docs
```

### Flutter
```bash
cd frontend
flutter pub get
flutter run
```

## Modules Implémentés
- ✅ Module 0 — Foundation (backend + flutter)
- ✅ Module 1 — Auth (JWT, register/login)
- ✅ Module 2 — Banque de Sujets (filtres, recherche, téléchargement)
- ✅ Module 3 — Quiz IA (génération Anthropic, sessions, stats)
- ✅ Module 4 — Forum (discussions, commentaires, catégories)
- ✅ Module 5 — Marketplace (produits, achats, profs vérifiés)
- ✅ Module 6 — Profil & Gamification (badges, classement, XP)
- ✅ Module 7 — Offline & Sync (cache local, sync automatique, downloads)

## Données Burkina Faso
- Niveaux : Primaire, Collège, Lycée, Université, Concours
- Classes : CP1→CM2, 6ème→3ème, Seconde→Terminale (A1,A2,B,C,D,E)
- Examens nationaux : CEP, BEPC, BAC (toutes séries)
- Concours : ENAREF, ENAM, Police, Gendarmerie, Douanes, Trésor, BUMIGEB, INSD, FONER...
- Monnaie : FCFA
- Mobile Money : Orange Money, Moov Money, Coris Money
