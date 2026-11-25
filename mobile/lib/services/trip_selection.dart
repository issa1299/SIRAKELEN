/// Logique pure de sélection du trajet en vedette sur l'écran Accueil.
/// Aucune dépendance Flutter : testable unitairement.

import 'dart:core';

/// Résultat du choix du trajet en vedette.
class TrajetEnVedetteResult {
  final Map<String, dynamic> trajet;
  /// 'confirme' (trajet_organise), 'en_attente' (en_cours_de_finalisation),
  /// 'sans_partenaire' (actif sans partenaire)
  final String contexte;
  final Map<String, dynamic>? partenaire;
  final String? partenairePrenom;
  final String? demandeId;
  final int nbAutresMemeJour;

  TrajetEnVedetteResult({
    required this.trajet,
    required this.contexte,
    this.partenaire,
    this.partenairePrenom,
    this.demandeId,
    this.nbAutresMemeJour = 0,
  });
}

/// Date relative affichée sur la pastille du trajet en vedette.
/// « Aujourd’hui · 07:30 », « Demain · 07:30 », sinon « Lun. 16 nov. · 07:30 ».
String dateRelative(String dateDeplacement, String heureDepart) {
  final now = DateTime.now();
  final aujourdhui = DateTime(now.year, now.month, now.day);
  final demain = aujourdhui.add(const Duration(days: 1));

  final parts = dateDeplacement.split('-');
  if (parts.length < 3) return '$dateDeplacement · $heureDepart';

  final d = DateTime(
    int.tryParse(parts[0]) ?? 0,
    int.tryParse(parts[1]) ?? 0,
    int.tryParse(parts[2]) ?? 0,
  );

  const joursCourt = [
    'Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.',
  ];
  const moisCourt = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  final estAujourdhui =
      d.year == aujourdhui.year &&
      d.month == aujourdhui.month &&
      d.day == aujourdhui.day;
  final estDemain =
      d.year == demain.year &&
      d.month == demain.month &&
      d.day == demain.day;

  if (estAujourdhui) return 'Aujourd’hui · $heureDepart';
  if (estDemain) return 'Demain · $heureDepart';
  return '${joursCourt[d.weekday - 1]} ${d.day} ${moisCourt[d.month - 1]} · $heureDepart';
}

/// Rôle lisible pour l'affichage.
String libelleRole(String? role) => role == 'conducteur' ? 'Conducteur' : 'Passager';

/// Adresse courte : quartier/lieu sans l'adresse complète.
/// Coupe après la virgule si présente, sinon garde les 3 premiers mots.
String adresseCourte(String adresse) {
  if (adresse.isEmpty) return adresse;
  if (adresse.contains(',')) return adresse.split(',').first.trim();
  final mots = adresse.split(' ');
  if (mots.length <= 3) return adresse;
  return '${mots.take(3).join(' ')}…';
}

/// Sous-titre date/heure/role pour la carte en vedette.
String sousTitreTrajet(Map<String, dynamic> t) {
  final role = t['role'] as String?;
  final transport = t['moyenTransport'] as String?;
  final places = t['placesDisponibles'] as int?;
  final buffer = StringBuffer();
  buffer.write('${t['dateDeplacement']} · ${t['heureDepart']}');
  buffer.write(' · ${libelleRole(role)}');
  if (role == 'conducteur') {
    buffer.write(' · ${transport ?? '—'}');
    buffer.write(' · $places place${places != null && places > 1 ? 's' : ''}');
  }
  return buffer.toString();
}

/// Choisit le trajet en vedette parmi les trajets de l'utilisateur.
///
/// Règles de priorité :
/// 1. Trajets à venir (date >= aujourd'hui) et non annulés uniquement
/// 2. Celui qui part le plus tôt (date + heure)
/// 3. À date/heure proche, un trajet CONFIRMÉ (trajet_organise) passe avant
///    un trajet EN COURS DE FINALISATION, qui passe avant ACTIF
/// 4. Regroupe les doublons (même date + depart + destination) et garde
///    le plus récent (creeLe le plus tardif)
TrajetEnVedetteResult choisirTrajetEnVedette(
  List<Map<String, dynamic>> trajets,
  List<Map<String, dynamic>> demandesRecues,
  DateTime maintenant,
) {
  final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);

  // --- Filtrer : à venir, non annulés ---
  final valides = <Map<String, dynamic>>[];
  for (final t in trajets) {
    final statut = t['statut'] as String? ?? '';
    if (statut == 'annule') continue;

    final dateStr = t['dateDeplacement'] as String? ?? '';
    if (dateStr.isEmpty) continue;

    final parts = dateStr.split('-');
    if (parts.length < 3) continue;

    final d = DateTime(
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
      int.tryParse(parts[2]) ?? 0,
    );
    if (d.isBefore(aujourdhui)) continue; // passé

    valides.add(t);
  }

  if (valides.isEmpty) {
    throw StateError('Aucun trajet en vedette');
  }

  // --- Regrouper les doublons (même date + depart + destination),
  //     garder le plus récent ---
  final groupes = <String, Map<String, dynamic>>{};
  for (final t in valides) {
    final key = '${t['dateDeplacement']}|${t['depart']}|${t['destination']}';
    final existant = groupes[key];
    if (existant == null) {
      groupes[key] = t;
    } else {
      final creeExistant = existant['creeLe'] as String? ?? '';
      final creeNouveau = t['creeLe'] as String? ?? '';
      if (creeNouveau.compareTo(creeExistant) > 0) {
        groupes[key] = t;
      }
    }
  }

  final uniques = groupes.values.toList();

  // --- Trier : date/heure croissante, confirmé avant en attente ---
  int statutRank(String s) {
    switch (s) {
      case 'trajet_organise':
        return 0; // confirmé
      case 'en_cours_de_finalisation':
        return 1; // en attente de finalisation
      case 'actif':
        return 2; // sans partenaire
      default:
        return 3;
    }
  }

  uniques.sort((a, b) {
    final dateA = a['dateDeplacement'] as String? ?? '';
    final dateB = b['dateDeplacement'] as String? ?? '';
    var cmp = dateA.compareTo(dateB);
    if (cmp != 0) return cmp;

    final heureA = a['heureDepart'] as String? ?? '';
    final heureB = b['heureDepart'] as String? ?? '';
    cmp = heureA.compareTo(heureB);
    if (cmp != 0) return cmp;

    return statutRank(a['statut'] as String? ?? '')
        .compareTo(statutRank(b['statut'] as String? ?? ''));
  });

  final meilleur = uniques.first;
  final statut = meilleur['statut'] as String? ?? '';

  String contexte;
  if (statut == 'trajet_organise') {
    contexte = 'confirme';
  } else if (statut == 'en_cours_de_finalisation') {
    contexte = 'en_attente';
  } else {
    contexte = 'sans_partenaire';
  }

  // Partenaire si en cours de finalisation (demande acceptee sur ce trajet)
  Map<String, dynamic>? partenaire;
  String? partenairePrenom;
  String? demandeId;
  if (statut == 'en_cours_de_finalisation') {
    final acceptee = demandesRecues
        .where((d) =>
            d['statut'] == 'acceptee' && d['ad']['id'] == meilleur['id'])
        .toList();
    if (acceptee.isNotEmpty) {
      partenaire = acceptee.first['demandeur'] as Map<String, dynamic>?;
      partenairePrenom = partenaire?['prenom'] as String?;
      demandeId = acceptee.first['id'] as String?;
    }
  }

  // Autres trajets le même jour (sauf le meilleur)
  final dateDuMeilleur = meilleur['dateDeplacement'] as String? ?? '';
  final nbAutres = uniques
      .where((t) => t['id'] != meilleur['id'] && t['dateDeplacement'] == dateDuMeilleur)
      .length;

  return TrajetEnVedetteResult(
    trajet: meilleur,
    contexte: contexte,
    partenaire: partenaire,
    partenairePrenom: partenairePrenom,
    demandeId: demandeId,
    nbAutresMemeJour: nbAutres,
  );
}
