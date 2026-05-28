/// Données de référence du système éducatif du Burkina Faso
class BFEducation {
  BFEducation._();

  static const levels = [
    {'id': 1, 'name': 'Primaire', 'icon': '🏫', 'color': 0xFF40C057},
    {'id': 2, 'name': 'Collège', 'icon': '📖', 'color': 0xFF339AF0},
    {'id': 3, 'name': 'Lycée', 'icon': '📚', 'color': 0xFFFF922B},
    {'id': 4, 'name': 'Université', 'icon': '🎓', 'color': 0xFFAE3EC9},
    {'id': 5, 'name': 'Concours', 'icon': '🏆', 'color': 0xFFFA5252},
  ];

  static const classes = {
    'primaire': ['CP1', 'CP2', 'CE1', 'CE2', 'CM1', 'CM2'],
    'college': ['6ème', '5ème', '4ème', '3ème'],
    'lycee': [
      'Seconde', 'Première A', 'Première C', 'Première D',
      'Terminale A1', 'Terminale A2', 'Terminale B',
      'Terminale C', 'Terminale D', 'Terminale E',
    ],
    'universite': ['Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2'],
    'concours': ['Général'],
  };

  static const examTypes = {
    'primaire': ['CEP', 'Examen Blanc', 'Devoir'],
    'college': ['BEPC', 'Examen Blanc', 'Devoir', 'Test entrée 6ème'],
    'lycee': ['BAC A', 'BAC D', 'BAC C', 'BAC H', 'BAC E', 'Examen Blanc', 'Devoir'],
    'universite': ['Partiel', 'Examen Final', 'Rattrapage'],
    'concours': [
      'ENAREF', 'ENAM', 'Police Nationale', 'Gendarmerie',
      'Armée de Terre', 'Douanes', 'Trésor Public',
      'BUMIGEB', 'INSD', 'FONER', 'Médecine', 'INFSS', 'IBAM',
    ],
  };

  static const matieres = [
    {'name': 'Mathématiques', 'icon': '📐', 'color': 0xFF2196F3},
    {'name': 'Physique-Chimie', 'icon': '⚗️', 'color': 0xFFFF5722},
    {'name': 'SVT', 'icon': '🌿', 'color': 0xFF4CAF50},
    {'name': 'Français', 'icon': '📝', 'color': 0xFF9C27B0},
    {'name': 'Philosophie', 'icon': '🤔', 'color': 0xFF607D8B},
    {'name': 'Histoire-Géo', 'icon': '🌍', 'color': 0xFF795548},
    {'name': 'Anglais', 'icon': '🇬🇧', 'color': 0xFF00BCD4},
    {'name': 'Sciences Éco', 'icon': '📈', 'color': 0xFF009688},
    {'name': 'Informatique', 'icon': '💻', 'color': 0xFF1E88E5},
  ];

  static const villes = [
    'Ouagadougou', 'Bobo-Dioulasso', 'Koudougou', 'Banfora',
    'Ouahigouya', 'Pouytenga', 'Kaya', 'Tenkodogo',
    'Fada N\'Gourma', 'Dédougou', 'Manga', 'Ziniaré',
  ];

  static const availableYears = [
    2030, 2029,2028,2027, 2026,2025,2024, 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015,
    2014, 2013, 2012, 2011, 2010,  
  ];

  static const paymentMethods = ['Orange Money', 'Moov Money', 'Coris Money'];
}

class AppConstants {
  AppConstants._();

  static const appName = 'Nafa Edu';
  static const appTagline = 'Révise. Apprends. Réussis.';

  // API
  static const baseUrl = 'https://nafa-edu-backend.onrender.com';
  // Render free tier peut mettre 50-60s à se réveiller — 90s laisse une marge
  static const apiTimeout = Duration(seconds: 90);

  // Cache
  static const cacheDuration = Duration(minutes: 15);

  // Pagination
  static const defaultPageSize = 20;

  // Points système
  static const pointsPerDownload = 5;
  static const pointsPerQuizCorrect = 10;
  static const pointsPerForumPost = 20;
  static const pointsPerForumComment = 10;

  // Storage keys
  static const keyAccessToken = 'access_token';
  static const keyRefreshToken = 'refresh_token';
  static const keyUserId = 'user_id';
  static const keyUserName = 'user_name';
  static const keyIsTeacher = 'is_teacher';
  static const keyOnboardingDone = 'onboarding_done';
}
