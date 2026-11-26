# Site officiel SiraKelen — Instructions

## Adresses publiques

| Élément | URL |
|---------|-----|
| **Site officiel (vitrine)** | `https://sirakelen-site.diassanaissiaka68.workers.dev` |
| **Application Flutter Web** | `https://sirakelen-app.diassanaissiaka68.workers.dev` |
| **Backend API** | `https://sirakele-api.onrender.com` |
| **Health check** | `https://sirakele-api.onrender.com/health` |

## Pages du site vitrine

Accueil, À propos, Fonctionnalités, Télécharger, Version Web, Contact, Conditions d'utilisation, Politique de confidentialité.

Navigation par hash (`#/a-propos`, `#/telecharger`, …) — compatible Cloudflare Workers sans `_redirects`.

## ⚠️ IMPORTANT — Lien de téléchargement de l'APK

Le fichier APK **Release** généré par le projet se trouve ici (hors du dossier web car Cloudflare limite les fichiers à 25 Mo) :

```
C:\Users\USER\OneDrive\Documentos\Default Project\sirakele\release-apk-sirakelen-v1.0.0.apk
```

Taille réelle : **~55,0 Mo** (build Release optimisé, jamais un debug).

### État actuel (version 1.0.0)

✅ Le **vrai APK Release** (54,97 Mo) est déjà publié sur GitHub Releases sous le nom `sirakelen-v1.0.0-release.apk`. L'ancien APK Debug (188 Mo) a été supprimé de la release. Le bouton du site pointe vers ce fichier release.

Lien direct : `https://github.com/issa1299/SIRAKELEN/releases/latest/download/sirakelen-v1.0.0-release.apk`

### Pour publier une nouvelle version (procédure simple)

1. **Construire l'APK release** :
   ```bash
   cd mobile
   flutter build apk --release
   ```
   Récupérer `build/app/outputs/flutter-apk/app-release.apk` ( Release, jamais Debug).

2. **Remplacer l'asset sur GitHub Releases** (API, avec un token GitHub) :
   ```bash
   # Supprimer l'ancien asset puis uploader le nouveau
   # GET  https://api.github.com/repos/issa1299/SIRAKELEN/releases/latest
   # DELETE https://api.github.com/repos/issa1299/SIRAKELEN/releases/assets/<ancien_id>
   # POST  https://uploads.github.com/repos/issa1299/SIRAKELEN/releases/<release_id>/assets?name=sirakelen-vX.Y.Z-release.apk
   ```
   Ou manuellement dans l'interface GitHub : éditer la release, supprimer l'ancien APK, glisser le nouveau.

3. **Mettre à jour `config.js`** (infos de version) : `version`, `buildNumber`, `releaseDate`, `apkFileName`, `apkSizeMiB`, et `apkUrl` si le nom du fichier change.

4. **Redéployer le site** :
   ```bash
   cd site-officiel
   npx wrangler deploy
   ```

## Déploiement

```bash
cd site-officiel
npx wrangler deploy
```

## Configuration à renseigner avant ouverture au public

Dans `config.js` :
- `contact.whatsapp` : remplacer `22370123456` par le vrai numéro SiraKelen.
- `contact.email` : vérifier l'adresse.
- `social.facebook` / `twitter` : renseigner seulement si réel (sinon laissé vide = lien masqué).

Le formulaire de contact utilise `mailto:` (aucun backend requis, aucun faux lien).

## Identité visuelle

Logo et photos réelles du projet réutilisés. Icônes SVG vectorielles (aucun emoji). Thème orange `#F77F00` / crème `#FDF6EE`, cohérent avec l'application.

## Séparation des éléments

- **Site vitrine** : `sirakelen-site` (ce dossier)
- **Application Web** : `sirakelen-app` (dossier `mobile/`, `wrangler.toml`)
- **Backend** : Render (`sirakele-api`)
- **APK** : GitHub Releases (fichier Release, pas Debug)
