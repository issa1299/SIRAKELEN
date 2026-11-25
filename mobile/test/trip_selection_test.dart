import 'package:flutter_test/flutter_test.dart';
import 'package:sirakele/services/trip_selection.dart';

void main() {
  // Helper : construit un trajet minimal
  Map<String, dynamic> makeTrajet({
    required String id,
    required String statut,
    required String date,
    required String heure,
    required String depart,
    required String destination,
    String? role,
    String? moyenTransport,
    int? placesDisponibles,
    String? creeLe,
  }) {
    return {
      'id': id,
      'statut': statut,
      'dateDeplacement': date,
      'heureDepart': heure,
      'depart': depart,
      'destination': destination,
      'role': role ?? 'conducteur',
      'moyenTransport': moyenTransport,
      'placesDisponibles': placesDisponibles,
      'creeLe': creeLe ?? '2026-11-10T08:00:00Z',
    };
  }

  final maintenant = DateTime(2026, 11, 15, 9, 0, 0);

  // -----------------------------------------------------------------------
  // Aucun trajet à venir
  // -----------------------------------------------------------------------
  test('aucun trajet à venir lève StateError', () {
    expect(
      () => choisirTrajetEnVedette(
        [
          makeTrajet(
            id: 't1',
            statut: 'annule',
            date: '2026-11-16',
            heure: '08:00',
            depart: 'A',
            destination: 'B',
          ),
        ],
        [],
        maintenant,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('trajets passés exclus', () {
    expect(
      () => choisirTrajetEnVedette(
        [
          makeTrajet(
            id: 't1',
            statut: 'actif',
            date: '2026-11-14', // hier
            heure: '08:00',
            depart: 'A',
            destination: 'B',
          ),
        ],
        [],
        maintenant,
      ),
      throwsA(isA<StateError>()),
    );
  });

  // -----------------------------------------------------------------------
  // Priorité : plus tôt d'abord
  // -----------------------------------------------------------------------
  test('prend le trajet qui part le plus tôt', () {
    final r = choisirTrajetEnVedette(
      [
        makeTrajet(
          id: 't2',
          statut: 'actif',
          date: '2026-11-16',
          heure: '10:00',
          depart: 'A',
          destination: 'B',
        ),
        makeTrajet(
          id: 't1',
          statut: 'actif',
          date: '2026-11-16',
          heure: '08:00',
          depart: 'C',
          destination: 'D',
        ),
      ],
      [],
      maintenant,
    );
    expect(r.trajet['id'], 't1');
  });

  // -----------------------------------------------------------------------
  // Priorité : confirmé avant en attente (même date/heure)
  // -----------------------------------------------------------------------
  test('confirmé passe avant en attente à même date/heure', () {
    final r = choisirTrajetEnVedette(
      [
        makeTrajet(
          id: 't_attente',
          statut: 'en_cours_de_finalisation',
          date: '2026-11-16',
          heure: '08:00',
          depart: 'A',
          destination: 'B',
        ),
        makeTrajet(
          id: 't_confirme',
          statut: 'trajet_organise',
          date: '2026-11-16',
          heure: '08:00',
          depart: 'C',
          destination: 'D',
        ),
      ],
      [],
      maintenant,
    );
    expect(r.trajet['id'], 't_confirme');
    expect(r.contexte, 'confirme');
  });

  test('en attente passe avant actif à même date/heure', () {
    final r = choisirTrajetEnVedette(
      [
        makeTrajet(
          id: 't_actif',
          statut: 'actif',
          date: '2026-11-16',
          heure: '08:00',
          depart: 'A',
          destination: 'B',
        ),
        makeTrajet(
          id: 't_attente',
          statut: 'en_cours_de_finalisation',
          date: '2026-11-16',
          heure: '08:00',
          depart: 'C',
          destination: 'D',
        ),
      ],
      [],
      maintenant,
    );
    expect(r.trajet['id'], 't_attente');
    expect(r.contexte, 'en_attente');
  });

  // -----------------------------------------------------------------------
  // Doublons : même date + depart + destination, garde le plus récent
  // -----------------------------------------------------------------------
  test('doublons garde le plus récent', () {
    final r = choisirTrajetEnVedette(
      [
        makeTrajet(
          id: 't_vieux',
          statut: 'actif',
          date: '2026-11-16',
          heure: '08:00',
          depart: 'A',
          destination: 'B',
          creeLe: '2026-11-10T08:00:00Z',
        ),
        makeTrajet(
          id: 't_recent',
          statut: 'actif',
          date: '2026-11-16',
          heure: '08:00',
          depart: 'A',
          destination: 'B',
          creeLe: '2026-11-15T08:00:00Z',
        ),
      ],
      [],
      maintenant,
    );
    expect(r.trajet['id'], 't_recent');
  });

  // -----------------------------------------------------------------------
  // Contexte sans partenaire
  // -----------------------------------------------------------------------
  test('actif sans partenaire = contexte sans_partenaire', () {
    final r = choisirTrajetEnVedette(
      [
        makeTrajet(
          id: 't1',
          statut: 'actif',
          date: '2026-11-16',
          heure: '08:00',
          depart: 'A',
          destination: 'B',
          role: 'conducteur',
          placesDisponibles: 3,
        ),
      ],
      [],
      maintenant,
    );
    expect(r.contexte, 'sans_partenaire');
    expect(r.partenaire, isNull);
  });

  // -----------------------------------------------------------------------
  // Partenaire si en cours de finalisation + demande acceptée
  // -----------------------------------------------------------------------
  test('en cours de finalisation avec demande acceptée = partenaire', () {
    final r = choisirTrajetEnVedette(
      [
        makeTrajet(
          id: 't1',
          statut: 'en_cours_de_finalisation',
          date: '2026-11-16',
          heure: '08:00',
          depart: 'A',
          destination: 'B',
        ),
      ],
      [
        {
          'id': 'd1',
          'statut': 'acceptee',
          'ad': {'id': 't1'},
          'demandeur': {'id': 'u2', 'prenom': 'Amina', 'nom': 'Diallo'},
        },
      ],
      maintenant,
    );
    expect(r.contexte, 'en_attente');
    expect(r.partenairePrenom, 'Amina');
    expect(r.partenaire?['id'], 'u2');
  });

  // -----------------------------------------------------------------------
  // nbAutresMemeJour
  // -----------------------------------------------------------------------
  test('compte les autres trajets le même jour', () {
    final r = choisirTrajetEnVedette(
      [
        makeTrajet(
          id: 't1',
          statut: 'actif',
          date: '2026-11-16',
          heure: '08:00',
          depart: 'A',
          destination: 'B',
        ),
        makeTrajet(
          id: 't2',
          statut: 'actif',
          date: '2026-11-16',
          heure: '10:00',
          depart: 'C',
          destination: 'D',
        ),
        makeTrajet(
          id: 't3',
          statut: 'actif',
          date: '2026-11-17',
          heure: '08:00',
          depart: 'E',
          destination: 'F',
        ),
      ],
      [],
      maintenant,
    );
    expect(r.nbAutresMemeJour, 1); // seulement t2 est le même jour que t1
  });

  // -----------------------------------------------------------------------
  // dateRelative
  // -----------------------------------------------------------------------
  test('dateRelative aujourd’hui', () {
    final aujourdhui = DateTime.now();
    final d = '${aujourdhui.year}-${aujourdhui.month.toString().padLeft(2, '0')}-${aujourdhui.day.toString().padLeft(2, '0')}';
    expect(dateRelative(d, '07:30'), 'Aujourd’hui · 07:30');
  });

  test('dateRelative demain', () {
    final demain = DateTime.now().add(const Duration(days: 1));
    final d = '${demain.year}-${demain.month.toString().padLeft(2, '0')}-${demain.day.toString().padLeft(2, '0')}';
    expect(dateRelative(d, '07:30'), 'Demain · 07:30');
  });

  test('dateRelative autre jour', () {
    expect(dateRelative('2026-11-30', '08:00'), 'Lun. 30 nov. · 08:00');
  });

  // -----------------------------------------------------------------------
  // adresseCourte
  // -----------------------------------------------------------------------
  test('adresseCourte coupe après virgule', () {
    expect(adresseCourte('Sirakoro, Bamako, Mali'), 'Sirakoro');
  });

  test('adresseCourte garde 3 mots max', () {
    expect(adresseCourte('Cité du Quartier Belle Vue'), 'Cité du Quartier…');
  });

  test('adresseCourte 3 mots ou moins inchangé', () {
    expect(adresseCourte('FST Bamako'), 'FST Bamako');
  });

  // -----------------------------------------------------------------------
  // libelleRole
  // -----------------------------------------------------------------------
  test('libelleRole conducteur', () {
    expect(libelleRole('conducteur'), 'Conducteur');
  });

  test('libelleRole passager', () {
    expect(libelleRole('passager'), 'Passager');
  });

  // -----------------------------------------------------------------------
  // sousTitreTrajet
  // -----------------------------------------------------------------------
  test('sousTitreTrajet conducteur', () {
    final t = {
      'dateDeplacement': '2026-11-16',
      'heureDepart': '08:00',
      'role': 'conducteur',
      'moyenTransport': 'Voiture',
      'placesDisponibles': 3,
    };
    expect(sousTitreTrajet(t), '2026-11-16 · 08:00 · Conducteur · Voiture · 3 places');
  });

  test('sousTitreTrajet passager', () {
    final t = {
      'dateDeplacement': '2026-11-16',
      'heureDepart': '08:00',
      'role': 'passager',
    };
    expect(sousTitreTrajet(t), '2026-11-16 · 08:00 · Passager');
  });
}
