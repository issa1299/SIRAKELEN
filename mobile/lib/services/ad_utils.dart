/// Petits utilitaires partages pour les AD (expiration, affichage).
/// Evite de dupliquer la logique entre l'accueil et l'ecran « Parcourir ».
import 'dart:core';

/// Un AD est « expire » s'il est annule, reserve, organise, ou si sa date/
/// son heure de depart est dans le passe.
bool adExpire(Map<String, dynamic> ad) {
  final statut = ad['statut'] as String? ?? '';
  if (statut != 'actif') return true;

  final dateStr = ad['dateDeplacement'] as String? ?? '';
  final parts = dateStr.split('-');
  if (parts.length < 3) return true;
  final d = DateTime(
    int.tryParse(parts[0]) ?? 0,
    int.tryParse(parts[1]) ?? 0,
    int.tryParse(parts[2]) ?? 0,
  );
  final now = DateTime.now();
  final jour = DateTime(now.year, now.month, now.day);
  if (d.isBefore(jour)) return true;
  if (d.isAfter(jour)) return false;

  final h = (ad['heureDepart'] as String?) ?? '00:00';
  final hp = h.split(':');
  final limite = DateTime(
    now.year,
    now.month,
    now.day,
    int.tryParse(hp.isNotEmpty ? hp[0] : '0') ?? 0,
    int.tryParse(hp.length > 1 ? hp[1] : '0') ?? 0,
  );
  return now.isAfter(limite);
}

/// L'utilisateur a un AD actif non expire (condition d'acces a « Parcourir »).
bool aAccesParcourir(Map<String, dynamic>? adActif) {
  if (adActif == null) return false;
  if (adActif['statut'] != 'actif') return false;
  return !adExpire(adActif);
}
