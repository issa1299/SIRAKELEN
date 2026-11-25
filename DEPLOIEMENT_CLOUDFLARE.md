# Déploiement SIRA KELEN sur Cloudflare Pages

## Prérequis

- Compte GitHub avec le dépôt `issa1299/SIRAKELEN`
- Compte Cloudflare (gratuit) : https://dash.cloudflare.com
- Backend déployé sur Render (https://sirakele-api.onrender.com)

## Étape 1 : Connecter le dépôt GitHub

1. Va sur https://dash.cloudflare.com
2. Menu **Workers & Pages** → **Create application** → **Pages** → **Connect to Git**
3. Autorise Cloudflare à accéder à ton compte GitHub
4. Sélectionne le dépôt **issa1299/SIRAKELEN**
5. Branche : **master**

## Étape 2 : Configurer le build

| Champ | Valeur |
|-------|--------|
| Framework preset | Flutter (ou None) |
| Build command | `cd mobile && flutter build web --release --dart-define=apiBaseUrl=https://sirakele-api.onrender.com` |
| Build output directory | `mobile/build/web` |
| Root directory | `/` |

## Étape 3 : Variables d'environnement (optionnel)

Dans **Settings → Environment variables** :
- `FLUTTER_VERSION` : `3.38.9` (si disponible)

## Étape 4 : Déployer

1. Clique sur **Save and Deploy**
2. Attends le build (~3-5 minutes)
3. L'URL sera du type : `https://sirakele.pages.dev`

## Étape 5 : Domaine personnalisé (optionnel)

1. **Custom domains** → **Set up a custom domain**
2. Entrez votre domaine (ex. `sirakele.ml` ou `app.sirakele.com`)
3. Suivez les instructions DNS (CNAME vers `sirakele.pages.dev`)
4. HTTPS est activé automatiquement

## Étape 6 : Configurer le backend Render

Dans Render → service `sirakele-api` → **Environment** :
- `CORS_ORIGINS` = `https://sirakele.pages.dev` (ou votre domaine custom)
- `DATABASE_URL` = (connection string Supabase)

## Étape 7 : Vérifier le déploiement

1. Ouvrir l'URL Cloudflare Pages dans Chrome
2. Vérifier : connexion, accueil, publication de trajet, carte
3. Tester l'installation PWA (Chrome → menu ⋮ → "Installer SIRA KELEN")
4. Lighthouse mobile : Performance, Accessibilité, PWA

## Mise à jour sans bloquer les utilisateurs

1. Push sur `master` → Cloudflare redéploie automatiquement
2. Le service worker détecte la nouvelle version
3. L'utilisateur voit « Nouvelle version disponible : recharger »
4. Les utilisateurs existants continuent avec l'ancienne version jusqu'au rechargement
5. Pas de coupure de service

## Fichiers de configuration

- `mobile/web/_headers` : cache et en-têtes de sécurité (géré automatiquement par Cloudflare Pages)
- `mobile/web/_redirects` : fallback SPA vers `index.html`
- `mobile/web/manifest.json` : configuration PWA
- `mobile/env.example` : documentation des variables d'environnement

## Commande de build locale (pour tester)

```bash
cd mobile
flutter build web --release --dart-define=apiBaseUrl=https://sirakele-api.onrender.com
cd build/web
python -m http.server 8080
# Ouvrir http://localhost:8080
```