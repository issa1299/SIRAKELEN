# Site officiel SiraKelen — Instructions

## Adresses publiques

| Élément | URL |
|---------|-----|
| **Site officiel (vitrine)** | `https://sirakelen-site.diassanaissiaka68.workers.dev` |
| **Administration complète** | `https://sirakelen-site.diassanaissiaka68.workers.dev/admin/` |
| **Ancien admin Flutter (inchangé)** | `https://sirakelen.pages.dev/login` |
| **Application Flutter Web** | `https://sirakelen-app.diassanaissiaka68.workers.dev` |
| **Proxy API (anti-CORS)** | `https://sirakelen-api-proxy.diassanaissiaka68.workers.dev` |
| **Backend API** | `https://sirakele-api.onrender.com` |
| **Health check** | `https://sirakele-api.onrender.com/health` |

## Administration complète

Le nouvel admin (`/admin/`) regroupe **5 onglets** :
1. **Aperçu** — statistiques (utilisateurs, AD, demandes, signalements…)
2. **Utilisateurs** — liste
3. **Trajets** — liste des Avis de Déplacement
4. **Signalements** — liste
5. **Mises à jour** — gestion centralisée des versions

Un lien vers l'**ancien admin Flutter** est présent dans l'en-tête — il reste inchangé et fonctionnel.

## Pages du site vitrine

Accueil, À propos, Fonctionnalités, Télécharger (version dynamique), Version Web, Contact, Conditions d'utilisation, Politique de confidentialité.

## Version actuelle (1.0.0)

✅ Le **vrai APK Release** (55,1 Mo) est publié sur GitHub Releases sous le nom `sirakelen-v1.0.0-release.apk`. La version 1.0.0 est **active** dans le backend (`/versions/latest?plateforme=android`). L'ancien APK Debug (188 Mo) a été supprimé.

Lien direct : `https://github.com/issa1299/SIRAKELEN/releases/latest/download/sirakelen-v1.0.0-release.apk`

### Pour publier une nouvelle version (procédure complète)

1. **Construire l'APK release** :
   ```bash
   cd mobile
   flutter build apk --release
   ```
   Récupérer `build/app/outputs/flutter-apk/app-release.apk` (Release, jamais Debug).

2. **Uploader l'APK sur GitHub Releases** :
   - https://github.com/issa1299/SIRAKELEN/releases
   - Supprimer l'ancien asset, glisser le nouveau nommé `sirakelen-vX.Y.Z-release.apk`
   - Publish release

3. **Créer le brouillon dans l'admin** (`/admin/` → onglet « Mises à jour ») :
   - Numéro de version, code de version, plateforme
   - URL de l'APK GitHub, taille en octets
   - Notes de mise à jour (1 nouveauté par ligne)
   - Case « obligatoire » si mise à jour bloquante
   - Le brouillon n'est **jamais publié automatiquement**

4. **Vérifier l'APK** (télécharger le lien, installer sur un téléphone test).

5. **Publier** via le bouton « Publier » du tableau (désactive les autres versions de la plateforme).

6. **Mettre à jour `mobile/pubspec.yaml`** (`version: X.Y.Z+N`) et rebuilder l'app.

7. **Redéployer** si besoin :
   ```bash
   cd site-officiel && npx wrangler deploy --config wrangler.toml
   cd api-proxy && npx wrangler deploy --config wrangler.toml
   ```

## Configuration Gmail API (OTP par email)

Variables sur Render (service `sirakele-api` → Environment) :
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GMAIL_REFRESH_TOKEN`
- `SMTP_FROM`

Vérifier avec : `GET https://sirakele-api.onrender.com/auth/diagnostic-email` → `{"strategie":"gmail-api"}`

## Identité visuelle

Logo et photos réelles du projet. Icônes SVG (aucun emoji). Thème orange `#F77F00` / crème `#FDF6EE`.

## Séparation des éléments

- **Site vitrine** : `sirakelen-site` (ce dossier)
- **Admin complet** : `site-officiel/admin/`
- **Application Web** : `sirakelen-app` (dossier `mobile/`)
- **Ancien admin Flutter** : `sirakelen.pages.dev` (inchangé)
- **Proxy API** : `sirakelen-api-proxy` (dossier `site-officiel/api-proxy/`)
- **Backend** : Render (`sirakele-api`)
- **APK** : GitHub Releases
