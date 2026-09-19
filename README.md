# SIRA KELEN

**Partagez la route. Partagez le cout.**

Application mobile de covoiturage au Mali. Mise en relation entre conducteurs et passagers grace a un matching intelligent par proximite geographique, itineraire et horaires.

## Structure

```
sirakele/
├── mobile/        Application Flutter (Android/iOS)
├── backend/       API NestJS (Node.js + PostgreSQL)
├── docs/          Dashboard admin, wireframes
└── README.md
```

## Stack technique

| Domaine | Technologie |
|---------|-------------|
| Mobile | Flutter 3, google_sign_in, sign_in_with_apple, flutter_map, geolocator |
| Backend | Node.js + NestJS, TypeORM, class-validator |
| Base de donnees | PostgreSQL 17 |
| Cartographie | OpenStreetMap (Nominatim geocodage + OSRM itineraires) |
| Authentification | Google OAuth, Apple Sign-In, email + code OTP |
| Notifications | Email (SMTP Gmail via nodemailer) |
| Admin | Dashboard HTML + API admin |

## Fonctionnalites

### Utilisateur
- Inscription / connexion via Google, Apple ou email + code OTP
- Publication d'Avis de Deplacement (AD) conducteur ou passager
- Selection de depart et destination sur carte interactive (2 etapes)
- Itineraire reel trace sur les routes (OSRM)
- Estimation distance et duree du trajet
- Matching intelligent par proximite geographique (Haversine) et compatibilite horaire
- Resultats de matching avec mini-carte et distances approximatives (confidentialite)
- Demandes de mise en relation avec statut (en attente / acceptee / refusee)
- Contact via WhatsApp
- Profil modifiable avec photo
- Contact d'urgence
- Code de recuperation

### Admin
- Dashboard avec statistiques (AD publies, trajets organises, signalements)
- Gestion des utilisateurs (verification, signalements)
- Connexion admin separee

## Lancement

```bash
# Backend
cd backend
npm install
npm run build
node dist/main.js

# Mobile
cd mobile
flutter pub get
flutter run
```

## API Backend (port 8080)

| Endpoint | Methode | Description |
|----------|---------|-------------|
| `/users` | POST | Inscription |
| `/users/:id` | GET | Profil utilisateur |
| `/users/:id` | PATCH | Modifier profil |
| `/auth/google` | POST | Connexion Google |
| `/auth/apple` | POST | Connexion Apple |
| `/auth/envoyer-code-email` | POST | Envoyer code OTP email |
| `/auth/verifier-email` | POST | Verifier code OTP |
| `/ads` | POST | Publier un AD |
| `/ads/mine/:userId` | GET | Mes AD |
| `/ads/compatibilites/:userId` | GET | Resultats matching |
| `/ads/publiques/:userId` | GET | Trajets publics |
| `/demandes` | POST | Envoyer demande |
| `/demandes/recues/:userId` | GET | Demandes recues |
| `/demandes/envoyees/:userId` | GET | Demandes envoyees |
| `/demandes/:id/accepter/:userId` | POST | Accepter |
| `/demandes/:id/refuser/:userId` | POST | Refuser |
| `/upload/photo/:userId` | POST | Upload photo |
| `/admin/stats` | GET | Statistiques admin |
| `/securite/contact-urgence` | PUT | Definir contact urgence |
| `/securite/signalements` | POST | Signaler un utilisateur |

## Equipe

- Issaka Diassana — Developpement mobile & backend
