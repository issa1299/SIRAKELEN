/**
 * Ecran « Parcourir tous les AD » — logique PURE (aucune dependance a la BDD).
 *
 * Objectif : consulter soi-meme la liste de tous les AD actifs, EN COMPLEMENT
 * de l'algorithme de matching (qui reste intact).
 *
 * Regles couvertes ici :
 *   1. ACCES : uniquement les utilisateurs ayant un AD ACTIF non expire
 *      (sinon 403 AD_ACTIF_REQUIS cote controleur) ;
 *   2. VISIBILITE : actif, a venir, places restantes, jamais le mien ;
 *   3. BADGE : reutilise le moteur de matching existant, sans le dupliquer ;
 *   4. TRI : pertinence (compatibles d'abord) ou date.
 *
 * Ce module n'importe QUE matching.ts : il reste testable sans TypeORM/Nest.
 */

import {
  AdMatching,
  NiveauCompatibilite,
  differenceMinutes,
  evaluerCompatibilite,
  haversineKm,
  normaliserLieu,
  prefiltrageRapide,
} from './matching';

/** Reflet de StatutAd.ACTIF (constante locale : ce module reste un module pur). */
export const STATUT_ACTIF = 'actif';

/** Code d'erreur explicite renvoye en 403 quand l'acces est refuse. */
export const CODE_ACCES_REFUSE = 'AD_ACTIF_REQUIS';
export const MESSAGE_ACCES_REFUSE = 'Publie un AD pour parcourir les trajets';

/** Plafond de lignes chargees pour le tri / la pagination cote serveur. */
export const MAX_LIGNES_PARCOURIR = 1000;

/** Vitesse moyenne utilisee pour l'estimation de duree (km/h). */
export const VITESSE_MOYENNE_KMH = 30;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/** Forme minimale d'un AD pour la regle d'acces / la visibilite. */
export interface AdDeBase {
  statut: string;
  dateDeplacement: string;
  heureDepart: string;
}

/** Forme complete d'un AD tel que renvoye par TypeORM. */
export interface AdEntite extends AdDeBase {
  id?: string;
  role?: string;
  depart?: string;
  destination?: string;
  moyenTransport?: string | null;
  placesDisponibles?: number | null;
  departLat?: number | null;
  departLng?: number | null;
  arriveeLat?: number | null;
  arriveeLng?: number | null;
  proprietaire?: {
    id: string;
    prenom?: string;
    nom?: string;
    verifie?: boolean;
    photoUrl?: string | null;
  } | null;
}

export interface ProprietaireAffiche {
  id: string;
  prenom: string;
  nom: string;
  verifie: boolean;
  photoUrl: string | null;
}

export interface LigneParcourir {
  id: string;
  role: string;
  depart: string;
  destination: string;
  dateDeplacement: string;
  heureDepart: string;
  moyenTransport: string | null;
  placesDisponibles: number | null;
  /** Longueur du trajet (a vol d'oiseau) — ne revele aucune position. */
  distanceKm: number | null;
  dureeMinutes: number | null;
  /** Distance entre MON depart et celui du candidat (confidentialite). */
  proximiteKm: number | null;
  ecartMinutes: number;
  proprietaire: ProprietaireAffiche;
  /** Badge « Compatible » : null = non valide par l'algorithme. */
  compatible: { niveau: NiveauCompatibilite; scoreFinal: number } | null;
}

// ---------------------------------------------------------------------------
// Dates / heures (l'app Mali est en UTC+0, on reste en UTC comme creer())
// ---------------------------------------------------------------------------

export function dateDuJour(d: Date): string {
  return d.toISOString().slice(0, 10);
}

export function heureDuJour(d: Date): string {
  return d.toISOString().slice(11, 16);
}

/** Date d'un AD normalisee en 'YYYY-MM-DD' (String vs Date selon TypeORM). */
export function jourAd(ad: { dateDeplacement: string }): string {
  return String(ad.dateDeplacement ?? '').slice(0, 10);
}

function heureAd(ad: { heureDepart: string }): string {
  return String(ad.heureDepart ?? '').slice(0, 5);
}

// ---------------------------------------------------------------------------
// 1. REGLE D'ACCES
// ---------------------------------------------------------------------------

/**
 * Un AD « compte » pour l'acces s'il est ACTIF et non expire :
 *   - statut actif (ni annule, ni reserve, ni organise) ;
 *   - date dans le futur, ou aujourd'hui avec une heure pas encore ecoulee.
 */
export function adNonExpire(
  ad: AdDeBase,
  maintenant: Date = new Date(),
): boolean {
  if (ad.statut !== STATUT_ACTIF) return false;

  const jour = dateDuJour(maintenant);
  const jourAd = String(ad.dateDeplacement ?? '').slice(0, 10);
  if (!jourAd) return false;
  if (jourAd < jour) return false;
  if (jourAd > jour) return true;

  // Meme jour : l'AD est expire des que l'heure de depart est passe.
  return heureAd(ad) >= heureDuJour(maintenant);
}

/** Vrai si l'utilisateur possede au moins un AD actif non expire. */
export function peutParcourir(
  mesAds: AdDeBase[],
  maintenant: Date = new Date(),
): boolean {
  return mesAds.some((ad) => adNonExpire(ad, maintenant));
}

/** L'AD de reference servant au prefiltrage par defaut et au badge. */
export function monAdActif(
  mesAds: AdDeBase[],
  maintenant: Date = new Date(),
): AdDeBase | null {
  return mesAds.find((ad) => adNonExpire(ad, maintenant)) ?? null;
}

// ---------------------------------------------------------------------------
// 2. REGLES DE VISIBILITE
// ---------------------------------------------------------------------------

export function adVisible(
  ad: AdEntite,
  userId: string,
  maintenant: Date = new Date(),
): boolean {
  // Jamais son propre AD.
  if (ad.proprietaire && ad.proprietaire.id === userId) return false;
  // Actif + a venir (adNonExpire verifie aussi le statut).
  if (!adNonExpire(ad, maintenant)) return false;
  // Places restantes : null = passager (toujours visible).
  if (ad.placesDisponibles != null && ad.placesDisponibles <= 0) return false;
  return true;
}

// ---------------------------------------------------------------------------
// 3. BADGE « COMPATIBLE » — reutilise le moteur existant, sans duplication
// ---------------------------------------------------------------------------

function versMatching(ad: AdEntite): AdMatching {
  return {
    departLat: ad.departLat ?? null,
    departLng: ad.departLng ?? null,
    arriveeLat: ad.arriveeLat ?? null,
    arriveeLng: ad.arriveeLng ?? null,
    depart: ad.depart ?? '',
    destination: ad.destination ?? '',
    heureDepart: ad.heureDepart ?? '',
  };
}

/**
 * Meme decision que la boucle interne de AdsService.compatibilites() :
 * meme date -> prefiltrageRapide -> evaluerCompatibilite -> niveau non null.
 * Aucune logique dupliquee : on rappelle les fonctions exportees par matching.ts.
 */
export function badgeCompatible(
  monAd: AdEntite,
  candidat: AdEntite,
): { niveau: NiveauCompatibilite; scoreFinal: number } | null {
  if (jourAd(monAd) !== jourAd(candidat)) return null;

  const ref = versMatching(monAd);
  const cible = versMatching(candidat);

  if (!prefiltrageRapide(ref, cible)) return null;

  const resultat = evaluerCompatibilite(ref, cible);
  if (!resultat.niveau) return null;

  return {
    niveau: resultat.niveau,
    scoreFinal: Math.round(resultat.scoreFinal * 10) / 10,
  };
}

// ---------------------------------------------------------------------------
// Construction de la ligne de reponse (CONFIDENTIALITE)
//   - ni telephone, ni coordonnees GPS exactes ;
//   - seulement libelles de zones + distances relatives.
// ---------------------------------------------------------------------------

function arrondi(v: number, pas: number): number {
  return Math.round(v / pas) * pas;
}

export function construireLigne(
  monAd: AdEntite,
  ad: AdEntite,
  proprietaire: ProprietaireAffiche,
): LigneParcourir {
  const aLeGps =
    ad.departLat != null &&
    ad.departLng != null &&
    ad.arriveeLat != null &&
    ad.arriveeLng != null;

  const distanceKm = aLeGps
    ? arrondi(
        haversineKm(
          ad.departLat as number,
          ad.departLng as number,
          ad.arriveeLat as number,
          ad.arriveeLng as number,
        ),
        0.1,
      )
    : null;

  const proximiteKm =
    monAd.departLat != null &&
    monAd.departLng != null &&
    ad.departLat != null &&
    ad.departLng != null
      ? arrondi(
          haversineKm(
            monAd.departLat,
            monAd.departLng,
            ad.departLat,
            ad.departLng,
          ),
          0.01,
        )
      : null;

  const ecartBrut = differenceMinutes(heureAd(monAd), heureAd(ad));
  const ecartMinutes =
    ecartBrut === Number.MAX_SAFE_INTEGER ? 9999 : ecartBrut;

  return {
    id: ad.id ?? '',
    role: ad.role ?? '',
    depart: ad.depart ?? '',
    destination: ad.destination ?? '',
    dateDeplacement: jourAd(ad),
    heureDepart: heureAd(ad),
    moyenTransport: ad.moyenTransport ?? null,
    placesDisponibles: ad.placesDisponibles ?? null,
    distanceKm,
    dureeMinutes:
      distanceKm == null
        ? null
        : Math.max(1, Math.round((distanceKm / VITESSE_MOYENNE_KMH) * 60)),
    proximiteKm,
    ecartMinutes,
    proprietaire,
    compatible: badgeCompatible(monAd, ad),
  };
}

// ---------------------------------------------------------------------------
// 4. TRI
// ---------------------------------------------------------------------------

/**
 * Pertinence : compatibles d'abord, puis score de l'algorithme,
 * puis proximite du depart, puis ecart d'horaire.
 */
export function comparerPertinence(
  a: LigneParcourir,
  b: LigneParcourir,
): number {
  const rangA = a.compatible ? 0 : 1;
  const rangB = b.compatible ? 0 : 1;
  if (rangA !== rangB) return rangA - rangB;

  if (a.compatible && b.compatible && a.compatible.scoreFinal !== b.compatible.scoreFinal) {
    return b.compatible.scoreFinal - a.compatible.scoreFinal;
  }

  const proxA = a.proximiteKm ?? Number.POSITIVE_INFINITY;
  const proxB = b.proximiteKm ?? Number.POSITIVE_INFINITY;
  if (proxA !== proxB) return proxA - proxB;

  if (a.ecartMinutes !== b.ecartMinutes) return a.ecartMinutes - b.ecartMinutes;

  return a.heureDepart.localeCompare(b.heureDepart);
}

/** Tri optionnel par date de depart. */
export function comparerDate(a: LigneParcourir, b: LigneParcourir): number {
  if (a.dateDeplacement !== b.dateDeplacement) {
    return a.dateDeplacement < b.dateDeplacement ? -1 : 1;
  }
  return a.heureDepart.localeCompare(b.heureDepart);
}

// ---------------------------------------------------------------------------
// Filtres de zone (insensible aux accents + correspondance par jetons)
// ---------------------------------------------------------------------------

export function zoneCorrespond(texte: string, filtre: string): boolean {
  const a = normaliserLieu(texte ?? '');
  const b = normaliserLieu(filtre ?? '');
  if (!b) return true; // pas de filtre
  if (!a) return false;
  if (a.includes(b) || b.includes(a)) return true;

  // « golf » doit matche « cite golf », « universite » doit matche
  // « universite de bamako ».
  const jetons = new Set(a.split(' ').filter((t) => t.length >= 3));
  return b.split(' ').some((t) => t.length >= 3 && jetons.has(t));
}
