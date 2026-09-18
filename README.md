# SIRA KÉLÉ

**Partagez la route. Partagez le coût.**

Application mobile de mise en relation basée sur la compatibilité des trajets, pour réduire les coûts de déplacement au Mali.

## Structure

```
sirakele/
├── mobile/    # Application Flutter (Android/iOS)
├── backend/   # API NestJS (Node.js + PostgreSQL)
├── docs/      # Cahier des charges, wireframes, feuille de route
└── README.md
```

## Stack technique

| Domaine | Technologie |
|---------|-------------|
| Mobile | Flutter |
| Backend | Node.js + NestJS |
| Base de données | PostgreSQL |
| Temps réel | Socket.IO |
| Cartographie | OpenStreetMap / Google Maps |
| Notifications | Firebase Cloud Messaging |
| Authentification | Numéro de téléphone + code SMS |

## Équipe

- Issaka Diassana — Développement mobile
- [Membre 2] — Backend
- [Membre 3] — Design & tests

## MVP

Inscription/connexion par téléphone, publication d'Avis de Déplacement (AD), matching par itinéraire/direction/heure, demandes de mise en relation, organisation du trajet via WhatsApp/téléphone, notifications, signalements.
npm run start:dev
flutter run