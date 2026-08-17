# CAHIER DES CHARGES — SIRA KÉLÉ v2
## Plateforme de mise en relation pour le partage de trajets urbains au Mali

**Mise à jour : Juillet 2026 — basé sur les résultats de l'enquête terrain (100 répondants)**

---

## Résumé des ajustements suite à l'enquête

| Point | Version initiale | Version ajustée (v2) | Validé par enquête |
|-------|------------------|---------------------|--------------------|
| Frais d'inscription | 500 FCFA | **GRATUITE** | 78,8% préfèrent inscription gratuite |
| Publication d'un AD | 200 FCFA | **100 FCFA** | 78,8% ont dit oui à 100 FCFA/AD |
| Vérification des profils | Fonctionnalité v2 | **Prioritaire (MVP)** | 36% l'ont demandé comme essentiel |
| Cible prioritaire | Grand public | **Étudiants (82%)** | 82% des répondants sont étudiants |
| Partenaires de trajet | Ouvert à tous | **"Toute personne fiable"** | 56% préfèrent cette option |
| Partage des frais | 50/50 | **Selon accord (49%)** ou 50/50 (38%) |

---

## 1. Présentation du projet

### 1.1 Contexte
Les Maliens sont confrontés à une augmentation constante des coûts de transport. **L'enquête révèle que 71% des personnes interrogées considèrent les coûts de transport comme une difficulté majeure**, et 43% dépensent plus de 1 000 FCFA par jour.

### 1.2 Cible validée par l'enquête
- **82% d'étudiants** (cible prioritaire)
- Quartiers principaux : Sirakoro, Golf, Kalaban Coura/Coro, Baco-Djicoroni
- Lieux fréquentés : Universités (FST, FSEG), Golf, Badalabougou, ACI 2000

### 1.3 Moyens de transport utilisés
| Moyen | % |
|-------|----|
| Moto/Voiture personnelle | 65% |
| Moto-taxi / Télimani | 26% |
| Sotrama | 20% |
| Taxi | 2% |

---

## 2. Modèle économique (VALIDÉ PAR ENQUÊTE)

| Poste | Prix | Taux d'acceptation |
|-------|------|-------------------|
| Inscription | **GRATUITE** | 78,8% |
| Publication d'un AD | **100 FCFA** | 78,8% |
| Consultation des AD | Gratuite | - |
| Messagerie | Gratuite | - |

> **Justification :** L'enquête montre que 78,8% des répondants acceptent de payer 100 FCFA par publication d'AD si l'inscription est gratuite. Contre seulement 36% pour une inscription à 1 000 FCFA avec AD inclus.

### Projection financière (estimation)
- Base : 1 000 utilisateurs actifs
- AD publiés par jour : ~200 (estimation basse)
- Revenus journaliers : 200 × 100 FCFA = **20 000 FCFA/jour**
- Revenus mensuels : ~**600 000 FCFA**

---

## 3. Expression des besoins fonctionnels (AJUSTÉS)

### 3.1 Nouvelles priorités suite à l'enquête

| Réf. | Fonctionnalité | Priorité | Justification enquête |
|------|---------------|----------|----------------------|
| F01 | Inscription gratuite | Essentielle | 78,8% valident |
| F02 | Authentification (téléphone + code) | Essentielle | - |
| F03 | Publication d'un AD (100 FCFA) | Essentielle | 78,8% acceptent 100 FCFA |
| F04 | Consultation et filtrage des AD | Essentielle | - |
| **F05** | **Mise en relation automatique** | **Essentielle** | **53,1% — priorité #1 des fonctionnalités** |
| **F06** | **Messagerie interne** | **Essentielle** | **43,9% — priorité #2** |
| **F07** | **Vérification des profils** | **Essentielle (MVP)** | **36% l'ont demandé + 51% inquiets pour la sécurité** |
| F08 | Choix du partenaire | Essentielle | - |
| F09 | Annulation d'un AD (sans remboursement) | Essentielle | - |
| F10 | Suppression automatique après accord | Essentielle | - |
| F11 | Paiement mobile money (100 FCFA/AD) | Essentielle | - |
| F12 | Back-office administrateur | Importante | - |
| F13 | **Notifications push** | **Importante** | Demande implicite |
| F14 | **Géolocalisation en temps réel** | **Importante** | Suggérée dans les retours libres |
| F15 | Système d'évaluation | Souhaitable (v2) | 15,3% — moins prioritaire |

### 3.2 Inquiétudes des utilisateurs à traiter dans l'app
1. **Sécurité** (51%) — Vérification des profils obligatoire, signalement, modération
2. **Retards** (50%) — Notifications, géolocalisation en temps réel, historique de ponctualité
3. **Manque de confiance** (36%) — Profils vérifiés, système de notation, historique des trajets

### 3.3 Personas mis à jour
- **Moussa** (82% des cas) : étudiant, moto personnelle, cherche à partager ses frais d'essence
- **Salimata** : étudiante, utilise moto-taxi, cherche un conducteur fiable pour réduire ses 2 000 FCFA/jour

---

## 4. Spécifications techniques (v2 — validée par l'équipe)

### 4.1 Architecture

| Domaine | Technologie | Rôle |
|---------|-------------|------|
| **Frontend mobile** | **Flutter** | App Android/iOS, une seule base de code |
| **Backend** | **Node.js + NestJS** | API, gestion des utilisateurs, trajets, logique métier |
| **Base de données** | **PostgreSQL** | Comptes, déplacements, demandes, messages, historiques |
| **Temps réel** | **Socket.IO** | Messagerie, notifications, mises à jour instantanées |
| **Cartographie** | **OpenStreetMap / Google Maps API** | Localisation, recherche de trajets, itinéraires |
| **Paiement** | **API Orange Money + Moov Money** | 100 FCFA par publication d'AD (MVP) |
| **Authentification** | **Firebase Auth** | Connexion par téléphone + code OTP |
| **Notifications** | **Firebase Cloud Messaging** | Alertes push |
| **Hébergement** | **OVH / Scaleway** | Serveurs |
| **Gestion de version** | **Git + GitHub** | Collaboration d'équipe |
| **Design** | **Figma** | Maquettes UI/UX |

> NestJS apporte une meilleure structure (modules, injection de dépendances, TypeScript) adaptée à un vrai produit évolutif après publication sur le Play Store.

### 4.2 Vérification des profils (priorité MVP)
- Vérification du numéro de téléphone (OTP)
- Validation par pièce d'identité + selfie
- Badge "Profil vérifié" visible dans l'app

---

## 5. Contraintes du projet

- **Sécurité juridique** : plusieurs répondants ont alerté sur les risques légaux en cas d'accident. Nécessité de clarifier le cadre légal et les responsabilités.
- **Connectivité** : l'application doit fonctionner en zone de faible réseau (mentionné dans les retours).
- **Confiance** : priorité absolue pour l'adoption.

---

## 6. Planning prévisionnel

| Phase | Livrable | Durée |
|-------|----------|-------|
| 1. Cadrage | Enquête validée (✓ 100 réponses) | Terminé |
| 2. Conception | Maquettes UI/UX + modèle de données | 3-5 semaines |
| 3. Développement MVP | Inscription, AD, matching, messagerie, vérification profils | 2-3 mois |
| 4. Intégration paiement | Orange Money + Moov Money (100 FCFA/AD) | 3-4 semaines |
| 5. Tests groupe pilote | Tests avec étudiants (cible prioritaire) | 3-4 semaines |
| 6. Lancement | Play Store + communication campus | 2 semaines |

---

## 7. KPIs de succès (AJUSTÉS)

- **100** répondants à l'enquête confirment le besoin
- **86%** pensent que le projet est utile pour le Mali
- **70,7%** sont intéressés par l'application
- Objectif pilote : 500 inscriptions gratuites, 100 AD/semaine, 50% de matching réussi

---

## 8. Risques et mitigation (AJOUTS)

| Risque | Impact | Mesure |
|--------|--------|--------|
| **Fraude/insécurité** (citée par 51%) | Critique | Vérification des profils MVP, système de signalement, géolocalisation partagée |
| **Responsabilité accident** (citée dans retours) | Critique | Consultation juridique, CGU claires, clause de non-responsabilité |
| **Faible adoption** | Élevé | Ciblage campus (82% étudiants), inscription gratuite, 100 FCFA/AD seulement |
| **Concurrence des moyens traditionnels** | Moyen | Prix très compétitif vs 1 000+ FCFA/jour actuels |
| **Dépendance connexion** | Moyen | Mode hors-ligne, légèreté de l'app |