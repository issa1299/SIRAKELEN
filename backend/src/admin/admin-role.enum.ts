/** Niveaux d'accès de l'espace administrateur SiraKelen. */
export enum AdminRole {
  SUPER_ADMIN = 'super_admin',
  ADMIN = 'admin',
  MODERATEUR = 'moderateur',
  SUPPORT = 'support',
  EDITEUR = 'editeur',
}

/** Permissions granulaires vérifiées côté serveur. */
export enum AdminPermission {
  // Utilisateurs
  USERS_LIRE = 'users:lire',
  USERS_MODIFIER = 'users:modifier',
  USERS_SUSPENDRE = 'users:suspendre',
  USERS_SUPPRIMER = 'users:supprimer',
  // Annonces / trajets
  ADS_LIRE = 'ads:lire',
  ADS_MODIFIER = 'ads:modifier',
  ADS_SUPPRIMER = 'ads:supprimer',
  // Signalements
  SIGNALEMENTS_LIRE = 'signalements:lire',
  SIGNALEMENTS_TRAITER = 'signalements:traiter',
  // Notifications
  NOTIFICATIONS_ENVOYER = 'notifications:envoyer',
  NOTIFICATIONS_LIRE = 'notifications:lire',
  // Mises à jour
  VERSIONS_LIRE = 'versions:lire',
  VERSIONS_PUBLIER = 'versions:publier',
  // Contenu du site
  CONTENU_LIRE = 'contenu:lire',
  CONTENU_MODIFIER = 'contenu:modifier',
  // Administration
  ADMINS_GERER = 'admins:gerer',
  PARAMETRES_MODIFIER = 'parametres:modifier',
  SAUVEGARDES = 'sauvegardes',
  JOURNAL_LIRE = 'journal:lire',
  STATS_LIRE = 'stats:lire',
}

/** Matrice des permissions par rôle (source de vérité côté serveur). */
export const ROLE_PERMISSIONS: Record<AdminRole, AdminPermission[]> = {
  [AdminRole.SUPER_ADMIN]: Object.values(AdminPermission),
  [AdminRole.ADMIN]: [
    AdminPermission.USERS_LIRE,
    AdminPermission.USERS_MODIFIER,
    AdminPermission.USERS_SUSPENDRE,
    AdminPermission.ADS_LIRE,
    AdminPermission.ADS_MODIFIER,
    AdminPermission.ADS_SUPPRIMER,
    AdminPermission.SIGNALEMENTS_LIRE,
    AdminPermission.SIGNALEMENTS_TRAITER,
    AdminPermission.NOTIFICATIONS_ENVOYER,
    AdminPermission.NOTIFICATIONS_LIRE,
    AdminPermission.VERSIONS_LIRE,
    AdminPermission.VERSIONS_PUBLIER,
    AdminPermission.CONTENU_LIRE,
    AdminPermission.CONTENU_MODIFIER,
    AdminPermission.STATS_LIRE,
    AdminPermission.JOURNAL_LIRE,
  ],
  [AdminRole.MODERATEUR]: [
    AdminPermission.USERS_LIRE,
    AdminPermission.ADS_LIRE,
    AdminPermission.ADS_MODIFIER,
    AdminPermission.ADS_SUPPRIMER,
    AdminPermission.SIGNALEMENTS_LIRE,
    AdminPermission.SIGNALEMENTS_TRAITER,
    AdminPermission.STATS_LIRE,
  ],
  [AdminRole.SUPPORT]: [
    AdminPermission.USERS_LIRE,
    AdminPermission.ADS_LIRE,
    AdminPermission.SIGNALEMENTS_LIRE,
    AdminPermission.NOTIFICATIONS_LIRE,
    AdminPermission.STATS_LIRE,
  ],
  [AdminRole.EDITEUR]: [
    AdminPermission.CONTENU_LIRE,
    AdminPermission.CONTENU_MODIFIER,
    AdminPermission.NOTIFICATIONS_LIRE,
    AdminPermission.STATS_LIRE,
  ],
};

export function roleAPerlission(
  role: AdminRole,
  permission: AdminPermission,
): boolean {
  return (ROLE_PERMISSIONS[role] || []).includes(permission);
}
