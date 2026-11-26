# SiraKelen — Site officiel & Administration centralisée

## Adresses publiques

| Élément | URL |
|---------|-----|
| **Site officiel (vitrine)** | `https://sirakelen-site.diassanaissiaka68.workers.dev` |
| **Administration centralisée** | `https://sirakelen-site.diassanaissiaka68.workers.dev/admin/` |
| **Ancien admin Flutter (inchangé)** | `https://sirakelen.pages.dev/login` |
| **Application Flutter Web** | `https://sirakelen-app.diassanaissiaka68.workers.dev` |
| **Proxy API (anti-CORS)** | `https://sirakelen-api-proxy.diassanaissiaka68.workers.dev` |
| **Backend API** | `https://sirakele-api.onrender.com` |
| **Health check** | `https://sirakele-api.onrender.com/health` |

Identifiants administrateur : `admin@sirakele.com` / `admin123` (compte promu automatiquement **SUPER_ADMIN** au premier login sécurisé ; changez le mot de passe depuis « Mon profil » — il sera haché avec scrypt).

---

## Administration centralisée (11 modules)

Interface responsive (ordinateur, tablette, mobile) avec barre latérale, recherche globale, notifications administratives, profil, tableaux filtrables, formulaires et fenêtres de confirmation.

1. **Tableau de bord** — statistiques 100 % réelles : utilisateurs, actifs, nouveaux inscrits (30 j), annonces, trajets organisés, signalements, demandes, messages, notifications envoyées, téléchargements APK, visites du site, taux de matching. Graphique à barres réel sur 30 jours (visites / téléchargements) et indicateurs de progression. Activité récente.
2. **Utilisateurs** — recherche (nom, téléphone, email), filtres statut/type, modification des champs autorisés, suspension, bannissement, réactivation, suppression **sous conditions** (refusée si le compte est lié à des annonces/demandes/signalements, pour préserver l'historique), consultation des signalements associés. Confirmation pour chaque action sensible.
3. **Annonces & trajets** — recherche par départ/destination, filtre par statut, modification des champs autorisés, suspension/réactivation, suppression.
4. **Signalements** — auteur, utilisateur signalé, annonce concernée, motif, traitement ou rejet avec note ; historique conservé dans le journal d'activité.
5. **Notifications** — envoi à tous / à un groupe (actifs, suspendus, admins, vérifiés, non vérifiés) / à un individu, programmation, historique avec résultat réel d'envoi, indicateur de configuration FCM.
6. **Mises à jour** — Android : création d'un brouillon (version, versionCode, URL APK Release, taille, nouveautés, obligatoire), publication, désactivation, historique. Web : version active affichée séparément, avec rappel explicite qu'un enregistrement administratif **ne prouve pas** un déploiement réel.
7. **Site officiel** — édition des textes de présentation, des liens de téléchargement, des coordonnées, des actualités et de la FAQ via le backend (aucune modification des fichiers du frontend).
8. **Paramètres** — clé/valeur pour le nom de la plateforme, les contacts, les liens officiels, la modération, la sécurité et les notifications.
9. **Administrateurs** — promotion/révocation avec 5 rôles : `SUPER_ADMIN`, `ADMIN`, `MODÉRATEUR`, `SUPPORT`, `ÉDITEUR`.
10. **Sauvegardes** — état réel (`DATABASE_URL`, `pg_dump`, fichiers), lancement manuel par un administrateur autorisé. **Aucun endpoint ne télécharge ni n'expose un fichier de sauvegarde.** Sur Render (offre gratuite), le disque est éphémère : l'interface l'indique clairement.
11. **Journal d'activité** — administrateur, action, date/heure, type et identifiant de l'objet, détail (connexions, modifications, suspensions, suppressions, publications, envois, paramètres, sauvegardes).

## Sécurité (côté serveur)

- Token HMAC-SHA256 signé avec `ADMIN_JWT_SECRET`, expiration 24 h, vérifié par `AdminGuard` sur **toutes** les routes admin et toutes les écritures `/versions`.
- Permissions granulaires vérifiées côté backend via `@Permissions(...)` (matrice `ROLE_PERMISSIONS`) — les boutons cachés ne sont qu'un confort d'interface.
- Mots de passe hachés avec `scrypt` dès modification ; compatibilité transitoire avec le mot de passe historique en clair pour ne pas casser l'accès existant.
- Rate limiting spécifique sur `/admin/login` (10 essais / 5 min).
- Champs sensibles (`motDePasse`, `codeRecuperation`) retirés de **tous** les endpoints publics et de toutes les réponses admin, y compris les relations.
- Messages privés et données personnelles préservés ; aucune suppression en cascade.

### Variables d'environnement à renseigner sur Render

| Variable | Rôle |
|----------|------|
| `DATABASE_URL` | Base PostgreSQL unique (déjà configurée) |
| `ADMIN_JWT_SECRET` | **Important** : chaîne longue et aléatoire pour signer les tokens |
| `ADMIN_SUPER_EMAIL` | `admin@sirakele.com` (promotion du premier super admin) |
| `FCM_SERVICE_ACCOUNT_JSON` | Optionnel : compte de service Firebase pour les push réels |
| `BACKUP_DIR` | Optionnel : dossier des sauvegardes serveur |

> ⚠️ **Déploiement backend** : le service Render `sirakele-api` déploie depuis la branche **`main`** (pas `master`). Pousser sur `main` déclenche le redéploiement.

### Firebase Cloud Messaging

Le backend implémente FCM HTTP v1 (OAuth2 signé avec la clé du compte de service, sans dépendance supplémentaire) et l'enregistrement des tokens via `POST /notifications/token`. **L'application mobile n'intègre pas encore `firebase_messaging`** : sans ce plugin côté Flutter, aucun push ne parvient au téléphone. Tant que `FCM_SERVICE_ACCOUNT_JSON` n'est pas défini, l'interface l'indique et le résultat d'envoi précise qu'aucun push n'a été émis — aucun chiffre n'est inventé.

---

## Versions

✅ Le vrai APK Release (~55,1 Mo) est publié sur GitHub Releases : `sirakelen-v1.0.0-release.apk`. La version 1.0.0 est active dans `/versions/latest?plateforme=android`.

Lien direct : `https://github.com/issa1299/SIRAKELEN/releases/latest/download/sirakelen-v1.0.0-release.apk`

### Procédure de publication d'une nouvelle version Android

1. `cd mobile && flutter build apk --release` (jamais de Debug).
2. Remplacer l'asset sur https://github.com/issa1299/SIRAKELEN/releases sous le nom `sirakelen-vX.Y.Z-release.apk`.
3. Admin → « Mises à jour » → créer un brouillon (version, build, URL, taille, notes, obligatoire).
4. Télécharger et installer l'APK sur un téléphone test.
5. Cliquer sur « Publier » (désactive les autres versions Android).
6. Mettre à jour `mobile/pubspec.yaml` (`version: X.Y.Z+N`) et rebuilder.

## Statistiques réelles

Le site enregistre les visites (`visite_site`, `visite_page`) et les clics sur le bouton APK (`telechargement_apk`) via `POST /evenements`, relayé par le proxy. Le tableau de bord lit ces compteurs dans la même base PostgreSQL que l'application — aucune donnée factice.

## Déploiement

```bash
cd site-officiel && npx wrangler deploy --config wrangler.toml
cd site-officiel/api-proxy && npx wrangler deploy --config wrangler.toml
git push origin main   # déclenche le déploiement Render du backend
```

## Adresse dédiée (optionnelle)

Une adresse du type `admin.sirakelen.pages.dev` peut être attachée via Cloudflare Pages → Custom Domains, puis un redirect depuis `/admin/`. Tant que le DNS n'est pas configuré, l'adresse fonctionnelle est celle indiquée en tête de document.
