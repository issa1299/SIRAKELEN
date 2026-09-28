/**
 * Moteur de matching SIRA KELEN — v3 (deterministe, sans IA/ML).
 *
 * Conserve de la v2 :
 *   - Haversine pour les distances locales ;
 *   - coordonnees GPS deja enregistrees ;
 *   - compatibilite depart + arrivee + horaire ;
 *   - score composite + niveaux (fort / moyen / faible).
 *
 * Ajoute :
 *   1. Prefiltrage peu couteux des candidats (performances) ;
 *   2. Gestion de la direction (cap + ecart angulaire) ;
 *   3. Comparaison des TRACES d'itineraires (projection sur le segment
 *      de reference, corridor lateral, ordre monte/descente, recouvrement) ;
 *   4. Distinction stricte COMPATIBILITE (filtre booleen) vs CLASSEMENT (score).
 *
 * Tous les seuils sont regroupes dans MATCHING_CONFIG (parametres configurables).
 */

export type NiveauCompatibilite = 'fort' | 'moyen' | 'faible';

export const MATCHING_CONFIG = {
  /** Seuil max distance depart ou arrivee (km). Au-dela = EXCLU. */
  DISTANCE_MAX_KM: 1.5,
  /** Fenetre horaire max (minutes). Au-dela = EXCLU. */
  ECART_MAX_MINUTES: 45,
  /** Ecart de cap max entre les deux trajets (degres). Au-dela = EXCLU. */
  DIRECTION_MAX_DEGRES: 35,
  /** Distance laterale max d'un point au trace de reference (km). Au-dela = EXCLU. */
  CORRIDOR_MAX_KM: 1.2,
  /** Part minimale du trace partagee (0..1). En-dessous = EXCLU. */
  RECOUVREMENT_MIN: 0.15,
  /** Tolerance de projection au-dela des extremites du segment (en fraction). */
  TOLERANCE_T: 0.08,
  /** Prefiltre geografique rapide : demi-boite englobante (degres). */
  PREFILTRE_BBOX_DEG: 0.05,
  /** Plafond de candidats evalues par AD (performances). */
  MAX_CANDIDATS: 300,
  /** Poids du classement (somme = 1). */
  POIDS_DEPART: 0.25,
  POIDS_ARRIVEE: 0.25,
  POIDS_HORAIRE: 0.25,
  POIDS_DIRECTION: 0.1,
  POIDS_RECOUVREMENT: 0.15,
  /** Seuils de niveaux sur le score final (0..100). */
  SEUIL_FORT: 70,
  SEUIL_MOYEN: 40,
  SEUIL_FAIBLE: 20,
};

/** Rayon de la Terre en kilometres. */
const R_KM = 6371;

// ---------------------------------------------------------------------------
// Haversine (conserve v2)
// ---------------------------------------------------------------------------
export function haversineKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ---------------------------------------------------------------------------
// Difference en minutes entre deux heures "HH:MM" (robuste)
// ---------------------------------------------------------------------------
export function differenceMinutes(h1: string, h2: string): number {
  const parse = (h: string): number => {
    const m = /^(\d{1,2}):(\d{2})/.exec((h || '').trim());
    if (!m) return NaN;
    return Number(m[1]) * 60 + Number(m[2]);
  };
  const a = parse(h1);
  const b = parse(h2);
  if (Number.isNaN(a) || Number.isNaN(b)) return Number.MAX_SAFE_INTEGER;
  return Math.abs(a - b);
}

// ---------------------------------------------------------------------------
// Cap (bearing) d'un trajet en degres 0..360
// ---------------------------------------------------------------------------
export function capTrajet(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const toDeg = (r: number) => (r * 180) / Math.PI;
  const dLng = toRad(lng2 - lng1);
  const y = Math.sin(dLng) * Math.cos(toRad(lat2));
  const x =
    Math.cos(toRad(lat1)) * Math.sin(toRad(lat2)) -
    Math.sin(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.cos(dLng);
  return (toDeg(Math.atan2(y, x)) + 360) % 360;
}

/** Ecart angulaire entre deux caps (0..180). */
export function ecartDirection(capA: number, capB: number): number {
  const d = Math.abs(capA - capB) % 360;
  return d > 180 ? 360 - d : d;
}

// ---------------------------------------------------------------------------
// Projection d'un point sur le TRACE de reference (segment A -> B).
// Approximation equirectangulaire locale (suffisante < 50 km, deterministe).
// Retourne t (0 = A, 1 = B), la distance laterale et la distance projetee.
// ---------------------------------------------------------------------------
export interface ProjectionTrace {
  t: number;
  lateralKm: number;
}

export function projeterSurTrace(
  pLat: number,
  pLng: number,
  aLat: number,
  aLng: number,
  bLat: number,
  bLng: number,
): ProjectionTrace {
  const refLat = (aLat + bLat) / 2;
  const kx = 111.32 * Math.cos((refLat * Math.PI) / 180);
  const ky = 110.57;
  const ax = 0;
  const ay = 0;
  const bx = (bLng - aLng) * kx;
  const by = (bLat - aLat) * ky;
  const px = (pLng - aLng) * kx;
  const py = (pLat - aLat) * ky;
  const abx = bx - ax;
  const aby = by - ay;
  const denom = abx * abx + aby * aby;
  if (denom === 0) {
    return { t: 0, lateralKm: Math.hypot(px, py) };
  }
  const t = (px * abx + py * aby) / denom;
  const projX = ax + t * abx;
  const projY = ay + t * aby;
  return { t, lateralKm: Math.hypot(px - projX, py - projY) };
}

// ---------------------------------------------------------------------------
function normaliserLieu(texte: string): string {
  return texte
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9 ]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

// ---------------------------------------------------------------------------
export interface AdMatching {
  departLat: number | null;
  departLng: number | null;
  arriveeLat: number | null;
  arriveeLng: number | null;
  depart: string;
  destination: string;
  heureDepart: string;
}

export interface ScoreResultat {
  /** null = incompatible (exclu par le filtre). */
  niveau: NiveauCompatibilite | null;
  scoreFinal: number;
  /** Conserves v2 (compat ascendante). */
  scoreItineraire: number;
  scoreHoraire: number;
  /** Nouveaux details v3. */
  scoreDirection: number;
  scoreRecouvrement: number;
  distDepartKm: number | null;
  distArriveeKm: number | null;
  ecartMinutes: number | null;
  ecartDirectionDeg: number | null;
  recouvrement: number | null;
  /** Motif d'exclusion (debug / logs), null si compatible. */
  motifExclusion: string | null;
}

const ZERO: ScoreResultat = {
  niveau: null,
  scoreFinal: 0,
  scoreItineraire: 0,
  scoreHoraire: 0,
  scoreDirection: 0,
  scoreRecouvrement: 0,
  distDepartKm: null,
  distArriveeKm: null,
  ecartMinutes: null,
  ecartDirectionDeg: null,
  recouvrement: null,
  motifExclusion: null,
};

function exclure(motif: string, partial?: Partial<ScoreResultat>): ScoreResultat {
  return { ...ZERO, ...partial, niveau: null, motifExclusion: motif };
}

// ---------------------------------------------------------------------------
// ETAPE 0 — Prefiltrage peu couteux (avant tout calcul trigonometrique lourd).
// Retourne true si le candidat merite une evaluation complete.
// ---------------------------------------------------------------------------
export function prefiltrageRapide(adRef: AdMatching, cand: AdMatching): boolean {
  const C = MATCHING_CONFIG;
  if (
    adRef.departLat == null ||
    adRef.departLng == null ||
    adRef.arriveeLat == null ||
    adRef.arriveeLng == null ||
    cand.departLat == null ||
    cand.departLng == null ||
    cand.arriveeLat == null ||
    cand.arriveeLng == null
  ) {
    return true; // sans GPS : laisser le fallback textuel trancher
  }
  if (
    Math.abs(adRef.departLat - cand.departLat) > C.PREFILTRE_BBOX_DEG ||
    Math.abs(adRef.departLng - cand.departLng) > C.PREFILTRE_BBOX_DEG ||
    Math.abs(adRef.arriveeLat - cand.arriveeLat) > C.PREFILTRE_BBOX_DEG ||
    Math.abs(adRef.arriveeLng - cand.arriveeLng) > C.PREFILTRE_BBOX_DEG
  ) {
    return false;
  }
  if (differenceMinutes(adRef.heureDepart, cand.heureDepart) > C.ECART_MAX_MINUTES) {
    return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Fonction principale : COMPATIBILITE (filtre) puis CLASSEMENT (score).
// ---------------------------------------------------------------------------
export function evaluerCompatibilite(
  adA: AdMatching,
  adB: AdMatching,
): ScoreResultat {
  const C = MATCHING_CONFIG;

  const coordsDisponibles =
    adA.departLat != null &&
    adA.departLng != null &&
    adA.arriveeLat != null &&
    adA.arriveeLng != null &&
    adB.departLat != null &&
    adB.departLng != null &&
    adB.arriveeLat != null &&
    adB.arriveeLng != null;

  // --- Sans GPS : fallback textuel deterministe (conserve v2) ---
  if (!coordsDisponibles) {
    const normDepA = normaliserLieu(adA.depart);
    const normDepB = normaliserLieu(adB.depart);
    const normArrA = normaliserLieu(adA.destination);
    const normArrB = normaliserLieu(adB.destination);
    const memeDestination =
      normArrA === normArrB ||
      normArrA.includes(normArrB) ||
      normArrB.includes(normArrA);
    if (!memeDestination) return exclure('destination-differente');
    const ecart = differenceMinutes(adA.heureDepart, adB.heureDepart);
    if (ecart > C.ECART_MAX_MINUTES) return exclure('horaire-trop-eloigne', { ecartMinutes: ecart });
    const memeDepart =
      normDepA === normDepB ||
      normDepA.includes(normDepB) ||
      normDepB.includes(normDepA);
    const scoreItineraire = memeDepart ? 80 : 50;
    const sHoraire = Math.max(0, 100 - (ecart / C.ECART_MAX_MINUTES) * 100);
    const scoreFinal = scoreItineraire * 0.6 + sHoraire * 0.4;
    return {
      ...ZERO,
      scoreFinal,
      scoreItineraire,
      scoreHoraire: sHoraire,
      scoreDirection: 50,
      scoreRecouvrement: 50,
      recouvrement: 0.5,
      ecartMinutes: ecart,
      niveau:
        scoreFinal >= C.SEUIL_FORT
          ? 'fort'
          : scoreFinal >= C.SEUIL_MOYEN
            ? 'moyen'
            : scoreFinal >= C.SEUIL_FAIBLE
              ? 'faible'
              : null,
      motifExclusion: scoreFinal >= C.SEUIL_FAIBLE ? null : 'score-insuffisant',
    };
  }

  // ================= COMPATIBILITE (filtres durs) =================
  const distDepart = haversineKm(adA.departLat!, adA.departLng!, adB.departLat!, adB.departLng!);
  const distArrivee = haversineKm(adA.arriveeLat!, adA.arriveeLng!, adB.arriveeLat!, adB.arriveeLng!);
  if (distDepart > C.DISTANCE_MAX_KM) return exclure('depart-trop-loin', { distDepartKm: distDepart, distArriveeKm: distArrivee });
  if (distArrivee > C.DISTANCE_MAX_KM) return exclure('arrivee-trop-loin', { distDepartKm: distDepart, distArriveeKm: distArrivee });

  const ecart = differenceMinutes(adA.heureDepart, adB.heureDepart);
  if (ecart > C.ECART_MAX_MINUTES) {
    return exclure('horaire-trop-eloigne', { distDepartKm: distDepart, distArriveeKm: distArrivee, ecartMinutes: ecart });
  }

  const capA = capTrajet(adA.departLat!, adA.departLng!, adA.arriveeLat!, adA.arriveeLng!);
  const capB = capTrajet(adB.departLat!, adB.departLng!, adB.arriveeLat!, adB.arriveeLng!);
  const ecartCap = ecartDirection(capA, capB);
  if (ecartCap > C.DIRECTION_MAX_DEGRES) {
    return exclure('direction-opposee', {
      distDepartKm: distDepart, distArriveeKm: distArrivee, ecartMinutes: ecart, ecartDirectionDeg: ecartCap,
    });
  }

  // Trace : le segment le plus long sert de reference (deterministe).
  const lenA = haversineKm(adA.departLat!, adA.departLng!, adA.arriveeLat!, adA.arriveeLng!);
  const lenB = haversineKm(adB.departLat!, adB.departLng!, adB.arriveeLat!, adB.arriveeLng!);
  const ref = lenA >= lenB ? adA : adB;
  const autre = lenA >= lenB ? adB : adA;
  const projDep = projeterSurTrace(
    autre.departLat!, autre.departLng!,
    ref.departLat!, ref.departLng!, ref.arriveeLat!, ref.arriveeLng!,
  );
  const projArr = projeterSurTrace(
    autre.arriveeLat!, autre.arriveeLng!,
    ref.departLat!, ref.departLng!, ref.arriveeLat!, ref.arriveeLng!,
  );
  const T = C.TOLERANCE_T;
  const dansTrace = (t: number) => t >= -T && t <= 1 + T;
  if (!dansTrace(projDep.t) || !dansTrace(projArr.t)) {
    return exclure('hors-trace', {
      distDepartKm: distDepart, distArriveeKm: distArrivee, ecartMinutes: ecart, ecartDirectionDeg: ecartCap,
    });
  }
  if (projDep.lateralKm > C.CORRIDOR_MAX_KM || projArr.lateralKm > C.CORRIDOR_MAX_KM) {
    return exclure('hors-corridor', {
      distDepartKm: distDepart, distArriveeKm: distArrivee, ecartMinutes: ecart, ecartDirectionDeg: ecartCap,
    });
  }
  // Ordre monte/descente le long du trace (sens du trajet).
  if (!(projDep.t < projArr.t)) {
    return exclure('ordre-inverse', {
      distDepartKm: distDepart, distArriveeKm: distArrivee, ecartMinutes: ecart, ecartDirectionDeg: ecartCap,
    });
  }
  const recouvrement = Math.min(1, Math.max(0, projArr.t - projDep.t));
  if (recouvrement < C.RECOUVREMENT_MIN) {
    return exclure('recouvrement-insuffisant', {
      distDepartKm: distDepart, distArriveeKm: distArrivee, ecartMinutes: ecart,
      ecartDirectionDeg: ecartCap, recouvrement,
    });
  }

  // ================= CLASSEMENT (scores 0..100) =================
  const sDep = Math.max(0, 100 - (distDepart / C.DISTANCE_MAX_KM) * 100);
  const sArr = Math.max(0, 100 - (distArrivee / C.DISTANCE_MAX_KM) * 100);
  const sHoraire = Math.max(0, 100 - (ecart / C.ECART_MAX_MINUTES) * 100);
  const sDir = Math.max(0, 100 - (ecartCap / C.DIRECTION_MAX_DEGRES) * 100);
  const sRec = Math.round(recouvrement * 100);
  const scoreItineraire = Math.min(sDep, sArr);
  const scoreFinal =
    sDep * C.POIDS_DEPART +
    sArr * C.POIDS_ARRIVEE +
    sHoraire * C.POIDS_HORAIRE +
    sDir * C.POIDS_DIRECTION +
    sRec * C.POIDS_RECOUVREMENT;

  let niveau: NiveauCompatibilite | null = null;
  if (scoreFinal >= C.SEUIL_FORT) niveau = 'fort';
  else if (scoreFinal >= C.SEUIL_MOYEN) niveau = 'moyen';
  else if (scoreFinal >= C.SEUIL_FAIBLE) niveau = 'faible';
  else return exclure('score-insuffisant', {
    distDepartKm: distDepart, distArriveeKm: distArrivee, ecartMinutes: ecart,
    ecartDirectionDeg: ecartCap, recouvrement,
  });

  return {
    niveau,
    scoreFinal,
    scoreItineraire,
    scoreHoraire: sHoraire,
    scoreDirection: sDir,
    scoreRecouvrement: sRec,
    distDepartKm: distDepart,
    distArriveeKm: distArrivee,
    ecartMinutes: ecart,
    ecartDirectionDeg: ecartCap,
    recouvrement,
    motifExclusion: null,
  };
}
