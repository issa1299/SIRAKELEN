/**
 * Moteur de matching SIRA KÉLÉ.
 * Compatibilité basée sur : itinéraire, direction et heure.
 * Seuls les AD actifs participent.
 */

export function normaliserLieu(texte: string): string {
  return texte
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9 ]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export function differenceMinutes(h1: string, h2: string): number {
  const [h1h, h1m] = h1.split(':').map(Number);
  const [h2h, h2m] = h2.split(':').map(Number);
  return Math.abs(h1h * 60 + h1m - (h2h * 60 + h2m));
}

export type NiveauCompatibilite = 'fort' | 'moyen' | 'faible';

export function calculerScore(
  departMoi: string,
  destinationMoi: string,
  heureMoi: string,
  departAutre: string,
  destinationAutre: string,
  heureAutre: string,
): { niveau: NiveauCompatibilite | null; points: number } {
  const depMoi = normaliserLieu(departMoi);
  const destMoi = normaliserLieu(destinationMoi);
  const depAutre = normaliserLieu(departAutre);
  const destAutre = normaliserLieu(destinationAutre);

  // Règle de direction : même destination finale obligatoire.
  const memeDestination =
    destMoi === destAutre ||
    destMoi.includes(destAutre) ||
    destAutre.includes(destMoi);
  if (!memeDestination) {
    return { niveau: null, points: 0 };
  }

  let points = 2; // même destination

  // Portion de départ commune.
  const departCommun =
    depMoi === depAutre ||
    depMoi.includes(depAutre) ||
    depAutre.includes(depMoi);
  if (departCommun) points += 1;

  // Compatibilité horaire.
  const diff = differenceMinutes(heureMoi, heureAutre);
  if (diff <= 30) points += 2;
  else if (diff <= 60) points += 1;

  let niveau: NiveauCompatibilite | null = null;
  if (points >= 4) niveau = 'fort';
  else if (points >= 3) niveau = 'moyen';
  else if (points >= 2) niveau = 'faible';

  return { niveau, points };
}
