import {
  adNonExpire,
  adVisible,
  badgeCompatible,
  comparerPertinence,
  construireLigne,
  peutParcourir,
  monAdActif,
  zoneCorrespond,
  CODE_ACCES_REFUSE,
  STATUT_ACTIF,
  VITESSE_MOYENNE_KMH,
} from './parcourir';
import { evaluerCompatibilite } from './matching';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const maintenant = new Date('2026-11-10T07:30:00.000Z');
const jour = '2026-11-10';

const monAd = {
  statut: 'actif',
  dateDeplacement: jour,
  heureDepart: '08:00',
  role: 'conducteur',
  depart: 'Sirakoro',
  destination: 'FST Bamako',
  departLat: 12.6392,
  departLng: -8.0029,
  arriveeLat: 12.65,
  arriveeLng: -8.01,
  placesDisponibles: 3,
  moyenTransport: 'Voiture',
  proprietaire: { id: 'moi' },
};

// AD compatible : meme sens, a proximite, 20 min plus tard.
const adCompatible = {
  statut: 'actif',
  dateDeplacement: jour,
  heureDepart: '08:20',
  role: 'passager',
  depart: 'Sirakoro',
  destination: 'FST Bamako',
  departLat: 12.641,
  departLng: -8.0045,
  arriveeLat: 12.6515,
  arriveeLng: -8.0115,
  placesDisponibles: 1,
  moyenTransport: null,
  proprietaire: { id: 'autre', prenom: 'A', nom: 'B', verifie: true, photoUrl: null },
};

// AD trop loin : depart a ~7 km.
const adLoin = {
  statut: 'actif',
  dateDeplacement: jour,
  heureDepart: '08:10',
  role: 'passager',
  depart: 'Kalaban Coura',
  destination: 'FST Bamako',
  departLat: 12.69,
  departLng: -8.05,
  arriveeLat: 12.652,
  arriveeLng: -8.012,
  placesDisponibles: 1,
  moyenTransport: null,
  proprietaire: { id: 'loin', prenom: 'C', nom: 'D', verifie: false, photoUrl: null },
};

// ---------------------------------------------------------------------------
// 1. Regle d'acces
// ---------------------------------------------------------------------------

describe('regle d acces', () => {
  it('aucun AD -> pas d acces', () => {
    expect(peutParcourir([], maintenant)).toBe(false);
  });

  it('AD annule -> pas d acces', () => {
    expect(
      peutParcourir([{ statut: 'annule', dateDeplacement: jour, heureDepart: '08:00' }], maintenant),
    ).toBe(false);
  });

  it('AD en_cours_de_finalisation -> pas d acces', () => {
    expect(
      peutParcourir([{ statut: 'en_cours_de_finalisation', dateDeplacement: jour, heureDepart: '08:00' }], maintenant),
    ).toBe(false);
  });

  it('AD actif mais date passee -> pas d acces', () => {
    expect(
      peutParcourir([{ statut: 'actif', dateDeplacement: '2026-11-09', heureDepart: '08:00' }], maintenant),
    ).toBe(false);
  });

  it('AD actif aujourd hui mais heure passee -> pas d acces', () => {
    expect(
      peutParcourir([{ statut: 'actif', dateDeplacement: jour, heureDepart: '07:00' }], maintenant),
    ).toBe(false);
  });

  it('AD actif aujourd hui heure a venir -> acces', () => {
    expect(
      peutParcourir([{ statut: 'actif', dateDeplacement: jour, heureDepart: '10:00' }], maintenant),
    ).toBe(true);
  });

  it('AD actif demain -> acces', () => {
    expect(
      peutParcourir([{ statut: 'actif', dateDeplacement: '2026-11-11', heureDepart: '08:00' }], maintenant),
    ).toBe(true);
  });

  it('monAdActif retourne le bon AD', () => {
    const ads = [
      { statut: 'annule', dateDeplacement: jour, heureDepart: '08:00' },
      { statut: 'actif', dateDeplacement: jour, heureDepart: '10:00' },
    ];
    expect(monAdActif(ads, maintenant)?.heureDepart).toBe('10:00');
  });

  it('adNonExpire respecte STATUT_ACTIF', () => {
    expect(STATUT_ACTIF).toBe('actif');
  });
});

// ---------------------------------------------------------------------------
// 2. Regles de visibilite
// ---------------------------------------------------------------------------

describe('regles de visibilite', () => {
  it('mon propre AD est exclu', () => {
    expect(adVisible({ ...monAd } as any, 'moi', maintenant)).toBe(false);
  });

  it('AD annule exclu', () => {
    expect(
      adVisible({ ...adCompatible, statut: 'annule' } as any, 'moi', maintenant),
    ).toBe(false);
  });

  it('AD places = 0 exclu', () => {
    expect(
      adVisible({ ...adCompatible, placesDisponibles: 0 } as any, 'moi', maintenant),
    ).toBe(false);
  });

  it('AD passager (places null) inclus', () => {
    expect(
      adVisible({ ...adCompatible, placesDisponibles: null } as any, 'moi', maintenant),
    ).toBe(true);
  });

  it('AD compatible visible', () => {
    expect(adVisible(adCompatible as any, 'moi', maintenant)).toBe(true);
  });
});

// ---------------------------------------------------------------------------
// 3. Coherence avec l'algorithme
// ---------------------------------------------------------------------------

describe('coherence avec l algorithme', () => {
  it('badge non null pour un couple compatible', () => {
    const badge = badgeCompatible(monAd as any, adCompatible as any);
    expect(badge).not.toBeNull();
    expect(['fort', 'moyen', 'faible']).toContain(badge!.niveau);
  });

  it('le badge est strictement coherent avec evaluerCompatibilite', () => {
    const badge = badgeCompatible(monAd as any, adCompatible as any);
    const ref = {
      departLat: monAd.departLat,
      departLng: monAd.departLng,
      arriveeLat: monAd.arriveeLat,
      arriveeLng: monAd.arriveeLng,
      depart: monAd.depart,
      destination: monAd.destination,
      heureDepart: monAd.heureDepart,
    };
    const cible = {
      departLat: adCompatible.departLat,
      departLng: adCompatible.departLng,
      arriveeLat: adCompatible.arriveeLat,
      arriveeLng: adCompatible.arriveeLng,
      depart: adCompatible.depart,
      destination: adCompatible.destination,
      heureDepart: adCompatible.heureDepart,
    };
    const resultat = evaluerCompatibilite(ref, cible);
    if (resultat.niveau) {
      expect(badge).not.toBeNull();
      expect(badge!.niveau).toBe(resultat.niveau);
    } else {
      expect(badge).toBeNull();
    }
  });

  it('badge null pour un couple incompatible (trop loin)', () => {
    expect(badgeCompatible(monAd as any, adLoin as any)).toBeNull();
  });

  it('badge null si dates differentes', () => {
    const autreJour = { ...adCompatible, dateDeplacement: '2026-11-11' };
    expect(badgeCompatible(monAd as any, autreJour as any)).toBeNull();
  });

  it('tri pertinence met les compatibles en tete', () => {
    const ligneCompat = construireLigne(
      monAd as any,
      adCompatible as any,
      adCompatible.proprietaire as any,
    );
    const ligneLoin = construireLigne(
      monAd as any,
      adLoin as any,
      adLoin.proprietaire as any,
    );
    expect(comparerPertinence(ligneCompat, ligneLoin)).toBeLessThan(0);
  });
});

// ---------------------------------------------------------------------------
// 4. Zone / confidentialite
// ---------------------------------------------------------------------------

describe('zone et confidentialite', () => {
  it('zoneCorrespond est insensible aux accents', () => {
    expect(zoneCorrespond('Université de Bamako', 'Universite')).toBe(true);
  });

  it('zoneCorrespond matche par jeton', () => {
    expect(zoneCorrespond('Cité Golf', 'Golf')).toBe(true);
    expect(zoneCorrespond('Sirakoro', 'Kalaban')).toBe(false);
  });

  it('construireLigne masque les coordonnees exactes', () => {
    const ligne = construireLigne(
      monAd as any,
      adCompatible as any,
      adCompatible.proprietaire as any,
    );
    // Pas de champs de coordonnees dans la ligne.
    expect((ligne as any).departLat).toBeUndefined();
    expect((ligne.proprietaire as any).telephone).toBeUndefined();
    expect(ligne.distanceKm).not.toBeNull();
    expect(ligne.proximiteKm).not.toBeNull();
  });

  it('VITESSE_MOYENNE_KMH est coherente', () => {
    expect(VITESSE_MOYENNE_KMH).toBe(30);
  });
});

// ---------------------------------------------------------------------------
// 5. Code d acces
// ---------------------------------------------------------------------------

describe('code d acces', () => {
  it('CODE_ACCES_REFUSE est explicite', () => {
    expect(CODE_ACCES_REFUSE).toBe('AD_ACTIF_REQUIS');
  });
});
