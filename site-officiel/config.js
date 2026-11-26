/**
 * Configuration centralisée du site officiel SIRA KELEN.
 * Pour publier une nouvelle version : modifier CE fichier uniquement.
 */

window.SIRAKELEN_CONFIG = {
  // === Version de l'application (sync avec mobile/pubspec.yaml) ===
  app: {
    name: 'SiraKelen',
    version: '1.0.0',
    buildNumber: '1',
    releaseDate: '26 novembre 2026',
    apkFileName: 'sirakelen-v1.0.0-release.apk',
    apkSizeMiB: '55.0',
    androidMin: 'Android 6.0 (API 23)',
    // Lien de téléchargement de l'APK RELEASE.
    // Par défaut : GitHub Releases (remplacer le fichier attaché à la release v1.0.0).
    apkUrl: 'https://github.com/issa1299/SIRAKELEN/releases/latest/download/sirakelen-v1.0.0-release.apk',
    // Fallback miroir local (si hébergé sur un service acceptant les >25 Mo).
    apkFallbackUrl: '',
  },

  // === Application Flutter Web déployée ===
  webApp: {
    url: 'https://sirakelen-app.diassanaissiaka68.workers.dev',
  },

  // === Backend API ===
  api: {
    url: 'https://sirakele-api.onrender.com',
    healthUrl: 'https://sirakele-api.onrender.com/health',
  },

  // === Contact ===
  // L'e-mail est celui utilisé par le projet (SMTP_FROM du backend).
  // WhatsApp laissé vide tant que le vrai numéro public n'est pas fourni :
  // aucun faux lien n'est affiché. À renseigner dans LISEZ-MOI.md avant publication.
  contact: {
    email: 'diassanaissiaka68@gmail.com',
    whatsapp: '',
    whatsappMessage: 'Bonjour, je souhaite contacter l’équipe SiraKelen.',
  },

  // === Réseaux sociaux (laisser vide = lien masqué, jamais de faux liens) ===
  social: {
    github: 'https://github.com/issa1299/SIRAKELEN',
    facebook: '',
    twitter: '',
  },
};
