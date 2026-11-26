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

### Pour publier une nouvelle version (procédure simple)

1. **Uploader l'APK sur GitHub Releases** :
   - Va sur https://github.com/issa1299/SIRAKELEN/releases
   - « Draft a new release » → tag `v1.0.0`, titre `SiraKelen v1.0.0`
   - Glisse le fichier `release-apk-sirakelen-v1.0.0.apk`
   - **Publish release**

2. **Mettre à jour `config.js`** (une seule ligne) :
   ```js
   apkUrl: 'https://github.com/issa1299/SIRAKELEN/releases/latest/download/sirakelen-v1.0.0-release.apk',
   ```
   (le nom du fichier attaché doit correspondre exactement)

3. **Mettre à jour les infos de version** dans `config.js` : `version`, `buildNumber`, `releaseDate`, `apkSizeMiB`, `apkFileName`.

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
