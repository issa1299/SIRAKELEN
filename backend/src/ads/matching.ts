/**
 * Moteur de matching SIRA KELEN — v2.
 * Compatibilite basee sur :
 *   - distance geographique (Haversine) entre points de depart et d'arrivee
 *   - compatibilite horaire
 * Seuls les AD actifs participent.
 */

export type NiveauCompatibilite = 'fort' | 'moyen' | 'faible';

/** Rayon de la Terre en kilometres. */
const R_KM = 6371;

/** Seuil max distance depart ou arrivee (km). Au-dela = EXCLU. */
const DISTANCE_MAX_KM = 1.5;

/** Fenetre horaire max (minutes). Au-dela = EXCLU. */
const ECART_MAX_MINUTES = 45;

/** Coefficients du score composite. */
const POIDS_ITINERAIRE = 0.6;
const POIDS_HORAIRE = 0.4;

/** Seuils d'affichage. */
const SEUIL_FORT = 70;
const SEUIL_MOYEN = 40;
const SEUIL_FAIBLE = 20;

// ---------------------------------------------------------------------------
// Distance de Haversine (en km) entre deux points GPS
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
// Difference en minutes entre deux heures "HH:MM"
// ---------------------------------------------------------------------------
export function differenceMinutes(h1: string, h2: string): number {
  const [h1h, h1m] = h1.split(':').map(Number);
  const [h2h, h2m] = h2.split(':').map(Number);
  return Math.abs(h1h * 60 + h1m - (h2h * 60 + h2m));
}

// ---------------------------------------------------------------------------
// Score a partir d'une distance (0..100)
// ---------------------------------------------------------------------------
function scoreDistance(distanceKm: number): number {
  return Math.max(0, 100 - (distanceKm / DISTANCE_MAX_KM) * 100);
}

// ---------------------------------------------------------------------------
// Score horaire (0..100)
// ---------------------------------------------------------------------------
function scoreHoraire(ecartMinutes: number): number {
  return Math.max(0, 100 - (ecartMinutes / ECART_MAX_MINUTES) * 100);
}

// ---------------------------------------------------------------------------
// Fallback : matching textuel quand les coordonnees GPS manquent
// ---------------------------------------------------------------------------
function normaliserLieu(texte: string): string {
  return texte
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9 ]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

// ---------------------------------------------------------------------------
// Interface d'entree pour une AD
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

// ---------------------------------------------------------------------------
// Resultat du scoring
// ---------------------------------------------------------------------------
export interface ScoreResultat {
  niveau: NiveauCompatibilite | null;
  scoreFinal: number;
  scoreItineraire: number;
  scoreHoraire: number;
}

// ---------------------------------------------------------------------------
// Fonction principale : evaluerCompatibilite (v2)
// ---------------------------------------------------------------------------
export function evaluerCompatibilite(
  adA: AdMatching,
  adB: AdMatching,
): ScoreResultat {
  const zero: ScoreResultat = {
    niveau: null,
    scoreFinal: 0,
    scoreItineraire: 0,
    scoreHoraire: 0,
  };

  // --- Etape 1 : distance geographique (Haversine) ---
  const coordsDisponibles =
    adA.departLat != null &&
    adA.departLng != null &&
    adA.arriveeLat != null &&
    adA.arriveeLng != null &&
    adB.departLat != null &&
    adB.departLng != null &&
    adB.arriveeLat != null &&
    adB.arriveeLng != null;

  let scoreItineraire: number;

  if (coordsDisponibles) {
    // Methode v2 : Haversine
    const distDepart = haversineKm(
      adA.departLat!,
      adA.departLng!,
      adB.departLat!,
      adB.departLng!,
    );
    const distArrivee = haversineKm(
      adA.arriveeLat!,
      adA.arriveeLng!,
      adB.arriveeLat!,
      adB.arriveeLng!,
    );

    if (distDepart > DISTANCE_MAX_KM || distArrivee > DISTANCE_MAX_KM) {
      return zero; // EXCLU
    }

    const sDep = scoreDistance(distDepart);
    const sArr = scoreDistance(distArrivee);
    scoreItineraire = Math.min(sDep, sArr); // maillon le plus faible
  } else {
    // Fallback textuel (avant geocodage complet)
    const normDepA = normaliserLieu(adA.depart);
    const normDepB = normaliserLieu(adB.depart);
    const normArrA = normaliserLieu(adA.destination);
    const normArrB = normaliserLieu(adB.destination);

    const memeDestination =
      normArrA === normArrB ||
      normArrA.includes(normArrB) ||
      normArrB.includes(normArrA);
    if (!memeDestination) return zero;

    const memeDepart =
      normDepA === normDepB ||
      normDepA.includes(normDepB) ||
      normDepB.includes(normDepA);
    scoreItineraire = memeDepart ? 80 : 50;
  }

  // --- Etape 2 : compatibilite horaire ---
  const ecart = differenceMinutes(adA.heureDepart, adB.heureDepart);
  if (ecart > ECART_MAX_MINUTES) return zero;

  const sHoraire = scoreHoraire(ecart);

  // --- Score composite ---
  const scoreFinal =
    scoreItineraire * POIDS_ITINERAIRE + sHoraire * POIDS_HORAIRE;

  let niveau: NiveauCompatibilite | null = null;
  if (scoreFinal >= SEUIL_FORT) niveau = 'fort';
  else if (scoreFinal >= SEUIL_MOYEN) niveau = 'moyen';
  else if (scoreFinal >= SEUIL_FAIBLE) niveau = 'faible';

  return { niveau, scoreFinal, scoreItineraire, scoreHoraire: sHoraire };
}
