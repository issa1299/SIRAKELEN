# Feuille de route — Développement de SIRA KÉLÉ

## Étape 0 : État des outils (machine de Issaka)

| Outil | Statut | Version |
|-------|--------|---------|
| Git | ✅ installé | 2.54.0 |
| Node.js | ✅ installé | v24.16.0 |
| npm | ✅ installé | 11.13.0 |
| Flutter | ✅ installé | 3.38.9 (stable) |
| Android SDK | ✅ installé | 36.1.0 |
| PostgreSQL | ❌ à installer | — |
| NestJS CLI | ⚠️ via npx | pas besoin de l'installer globalement |
| GitHub CLI (`gh`) | ❌ à installer (optionnel) | — |

> Flutter Doctor : OK pour Android. Visual Studio n'est requis que pour les apps Windows desktop → inutile pour notre projet.

## Étape 1 : Installations à faire (chaque membre)

### Tous les membres
1. **Git** : https://git-scm.com/downloads
2. **Node.js LTS** : https://nodejs.org (v22 LTS recommandée pour toute l'équipe)
3. **Flutter** : https://docs.flutter.dev/get-started/install/windows
   - Vérifier : `flutter doctor` (Android toolchain ✅ obligatoire)

### Responsable backend (ou tous si possible)
4. **PostgreSQL** : https://www.postgresql.org/download/windows/
   - Mot de passe `postgres` à noter dans un fichier `.env` (jamais dans le code)
5. Vérifier : `psql --version`

### Responsable mobile
6. **Android Studio** (si pas encore fait) : https://developer.android.com/studio
   - Plus simple pour créer les appareils virtuels (émulateurs)

## Étape 2 : Config Git (une seule fois, par membre)

```bash
git config --global user.name "TonNom"
git config --global user.email "tonemail@gmail.com"
```

⚠️ Issaka : ton email git est encore `votre@email.com` → à corriger :
```bash
git config --global user.email "diassanaissiaka68@gmail.com"
```

## Étape 3 : Créer le dépôt GitHub

1. Créer un dépôt **privé** nommé `sirakele` sur github.com (compte du chef d'équipe)
2. Ajouter les 3 membres en collaborateurs
3. Le chef de projet clone le dépôt vide :
```bash
git clone https://github.com/<compte>/sirakele.git
```

## Étape 4 : Structure du projet

```
sirakele/
├── mobile/        # App Flutter (Issaka)
├── backend/       # API NestJS (Backend dev)
├── docs/          # cahier-des-charges.md, maquettes, feuille-de-route
└── README.md      # Présentation du projet
```

## Étape 5 : Plan de développement (ordre recommandé)

| # | Tâche | Responsable | Durée |
|---|-------|-------------|-------|
| 1 | **Dépôt GitHub + structure** + README | Chef de projet | 1 j |
| 2 | `flutter create mobile` + `nest new backend` | Mobile / Backend | 1 j |
| 3 | **Base de données** : schéma PostgreSQL (users, trips, requests, messages, reviews) | Backend | 2 j |
| 4 | **Inscription/connexion** par téléphone OTP (Firebase Auth) | Mobile + Backend | 5 j |
| 5 | **Profil utilisateur** + vérification (téléphone + badge) | Mobile + Backend | 4 j |
| 6 | **Publication d'un trajet** (100 FCFA, intégration Orange/Moov) | Backend + Mobile | 5 j |
| 7 | **Recherche + matching automatique** | Backend | 4 j |
| 8 | **Demande de partage** + acceptation/refus | Mobile + Backend | 3 j |
| 9 | **Chat temps réel** (Socket.IO) | Backend + Mobile | 5 j |
| 10 | **Notifications push** (FCM) | Mobile + Backend | 3 j |
| 11 | **Tests groupe pilote** (étudiants) | Toute l'équipe | 3-4 sem |

## Étape 6 : Règles de travail en équipe

- Travailler sur des **branches** (`feature/nom-fonctionnalité`) → fusion dans `main`
- Faire une **pull request** + revue avant de merger
- Les secrets (clés API, mots de passe) vont dans `.env` (jamais commités)
- Commits en français, message clair : `feat: inscription par téléphone`
