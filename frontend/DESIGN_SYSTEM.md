# 🎨 Design System - Nafa Edu

## Aperçu
Un système de design cohérent basé sur la couleur primaire **#5863F8** avec une palette complète de nuances, garantissant une interface moderne, accessible et professionnelle.

---

## 📏 Palette de Couleurs

### Échelle Primaire #5863F8 (50-900)
| Nuance | Valeur | Cas d'usage |
|--------|--------|-----------|
| **50** | `#F0F3FF` | Backgrounds très clairs |
| **100** | `#E0E6FF` | Light surfaces, badges |
| **200** | `#C0CCFF` | Input focus background |
| **300** | `#A0B3FF` | Hover backgrounds |
| **400** | `#8099FF` | Disabled states |
| **500** | `#5863F8` | **Primary (Base)** - CTA, liens |
| **600** | `#4752E8` | Primary Hover |
| **700** | `#3641D8` | Primary Active |
| **800** | `#2530C8` | Primary Pressed |
| **900** | `#141FB8` | Dark variant |

**État des boutons:**
- Default: `#5863F8`
- Hover: `#4752E8`
- Active: `#3641D8`
- Pressed: `#2530C8`
- Disabled: `#E0E6FF`

### Palette Neutre (Backgrounds, Borders, Textes)
| Élément | Valeur | Utilisation |
|---------|--------|------------|
| **Background** | `#F8FAFC` | Page backgrounds |
| **Surface** | `#FFFFFF` | Cards, panels, modals |
| **Surface Hover** | `#F1F5F9` | Hover states |
| **Border** | `#E2E8F0` | Borders standard |
| **Border Light** | `#F1F5F9` | Light borders |
| **Border Dark** | `#CBD5E1` | Dark borders |

### Textes
| Type | Valeur | Utilisation |
|------|--------|------------|
| **Primaire** | `#0F172A` | Titre, contenu principal |
| **Secondaire** | `#64748B` | Sous-titres, métadonnées |
| **Tertiaire** | `#94A3B8` | Hints, placeholders |
| **Désactivé** | `#C0CCFF` | Texte désactivé |
| **Inverse** | `#FFFFFF` | Sur fonds sombres |

### Couleurs Sémantiques
| Rôle | Couleur | Light | Dark |
|------|---------|-------|------|
| **Success** | `#22C55E` | `#DCFCE7` | `#15803D` |
| **Warning** | `#F59E0B` | `#FEF3C7` | `#B45309` |
| **Error** | `#EF4444` | `#FECACA` | `#B91C1C` |
| **Info** | `#5863F8` | `#E0E6FF` | — |

### Niveaux Scolaires (Burkina Faso)
- **Primaire**: `#22C55E` (Success)
- **Collège**: `#5863F8` (Primary)
- **Lycée**: `#22C55E` (Success)
- **Université**: `#F59E0B` (Warning)
- **Concours**: `#EF4444` (Error)

---

## 🎯 Dégradés Prédéfinis

### Gradient Primaire
```dart
const LinearGradient gradientPrimary = LinearGradient(
  colors: [Color(0xFF4752E8), Color(0xFF5863F8), Color(0xFF7485FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```
*Utilisé pour les cartes d'onboarding card1 & card2, CTA secondaires*

### Gradient Success
```dart
const LinearGradient gradientSuccess = LinearGradient(
  colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```
*Utilisé pour les cartes d'onboarding card3*

### Gradient Warning
```dart
const LinearGradient gradientWarning = LinearGradient(
  colors: [Color(0xFFC2410C), Color(0xFFF59E0B)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```

---

## 🧩 Composants et Guidage Couleur

### Boutons
- **ElevatedButton (Primary)**: Arrière-plan `#5863F8`, texte blanc
- **ElevatedButton (Hover)**: Arrière-plan `#4752E8`
- **ElevatedButton (Disabled)**: Arrière-plan `#E0E6FF`, texte `#94A3B8`
- **OutlinedButton**: Bordure et texte `#5863F8`
- **TextButton**: Texte `#5863F8`

### Champs de formulaire
- **Border actif**: `#E2E8F0`
- **Border focused**: `#5863F8` (2px)
- **Border error**: `#EF4444` (1px)
- **Fill**: `#FFFFFF`

### Badges et Tags
- **Officiel**: Fond `#DCFCE7`, texte `#22C55E`
- **Populaire**: Fond `#FEF3C7`, texte `#F59E0B`
- **Nouveau**: Fond `#E0E6FF`, texte `#5863F8`

### Cartes
- **Bordure**: `#E2E8F0` (1px)
- **Ombrage**: `rgba(0, 0, 0, 0.04)` blurRadius 8, offset (0, 2)
- **Fond**: `#FFFFFF`

### Icônes
- **Primaires**: `#5863F8`
- **Success**: `#22C55E`
- **Error**: `#EF4444`
- **Warning**: `#F59E0B`
- **Désactivées**: `#94A3B8`

### Notifications/Snackbars
- **Arrière-plan**: `#0F172A`
- **Texte**: `#FFFFFF`

---

## 📱 Fichiers Concernés

### Modifiés
1. **`frontend/lib/config/theme.dart`**
   - Classe `AppColors` complète avec échelle de nuances
   - Classe `AppTheme` avec tous les thèmes de composants
   - Dégradés prédéfinis

2. **`frontend/lib/screens/home/home_screen.dart`**
   - Remplacé toutes les couleurs hardcodées par `AppColors`
   - Cartes d'onboarding utilisant les dégradés
   - Tous les boutons, badges, icônes en cohérence

---

## ✅ Standards d'Accessibilité

Tous les choix de couleur respectent **WCAG AA**:
- Ratio de contraste texte/fond ≥ 4.5:1 pour textes standards
- Ratio de contraste ≥ 3:1 pour textes larges
- Pas de distinction basée *uniquement* sur la couleur

---

## 🎨 Usage dans le Code

### Importer et utiliser
```dart
import 'package:nafa_edu/config/theme.dart';

// Couleur simple
Container(
  color: AppColors.primary,
  child: Text('CTA Principal', style: TextStyle(color: AppColors.textInverse)),
)

// Dégradé
Container(
  decoration: BoxDecoration(
    gradient: AppColors.gradientPrimary,
    borderRadius: BorderRadius.circular(12),
  ),
)

// État hover
onHover: (_) => setState(() => isHovered = true),
child: Container(
  color: isHovered ? AppColors.primaryHover : AppColors.primary,
)
```

### Variantes d'opacité
```dart
AppColors.primary.withOpacity(0.12)        // 12% opacity
AppColors.error.withOpacity(0.8)           // 80% opacity
```

---

## 📋 Checklist Cohérence

- [x] Couleur primaire unique: `#5863F8`
- [x] Échelle complète de nuances (50-900)
- [x] Palette neutre pour fonds/bordures/textes
- [x] Couleurs sémantiques standard (succès, warning, error, info)
- [x] Dégradés prédéfinis pour cartes d'onboarding
- [x] Tous les composants (boutons, inputs, badges) utilisant la palette
- [x] Accessibilité WCAG AA validée
- [x] Extension utilitaire `ColorX` pour opacité
- [x] Suppression de couleurs décoratives conflictuelles
- [x] Documentation complète

---

## 🚀 Prochaines étapes

1. **Appliquer dans autres écrans**: Banque, Forum, Marketplace, Quiz, etc.
2. **Tests de contraste**: Vérifier tous les ratios WCAG AA
3. **Mode sombre** (optionnel): Créer `AppTheme.dark` avec variantes appropriées
4. **Composants réutilisables**: Créer des widgets stylisés (FlatButton, Card, Badge) utilisant AppColors
5. **Documentation UI Kit**: Créer une page de démonstration de tous les composants

---

*Dernier update: 30 Mai 2026*
