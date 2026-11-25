#!/bin/bash
# Build de production pour le web (Cloudflare Pages)
# Usage : ./scripts/build_web_prod.sh

set -e

cd "$(dirname "$0")/.."

echo "=== Build web production ==="
flutter build web --release \
  --dart-define=apiBaseUrl=https://sirakele-api.onrender.com \
  --no-wasm-dry-run

echo ""
echo "=== Build termine ==="
echo "Dossier de sortie : build/web/"
echo "Poids total :"
du -sh build/web
echo ""
echo "=== Fichiers generes ==="
ls -la build/web/_headers build/web/_redirects build/web/manifest.json