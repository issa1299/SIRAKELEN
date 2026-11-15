import 'package:flutter/material.dart';
import '../main.dart';

/// Composant carte AD partage (mes AD + liste « Parcourir »).
/// Extras optionnels : badge « Compatible », distance/duree, proprietaire.
class CarteAd extends StatelessWidget {
  final Map<String, dynamic> ad;
  final bool archive;
  final Map<String, dynamic>? compatible;
  final double? distanceKm;
  final int? dureeMinutes;
  final double? proximiteKm;
  final Map<String, dynamic>? proprietaire;
  final VoidCallback? onTap;

  const CarteAd({
    super.key,
    required this.ad,
    this.archive = false,
    this.compatible,
    this.distanceKm,
    this.dureeMinutes,
    this.proximiteKm,
    this.proprietaire,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statut = ad['statut'] as String? ?? '';
    final barre = statut == 'trajet_organise' || statut == 'annule';
    final isConducteur = ad['role'] == 'conducteur';
    final niveau = compatible?['niveau'] as String?;
    Color? pillBg;
    Color? pillText;
    if (niveau != null) {
      switch (niveau) {
        case 'fort':
          pillBg = kGreenLight;
          pillText = kGreen;
          break;
        case 'moyen':
          pillBg = const Color(0xFFFFE8D4);
          pillText = const Color(0xFFB35A00);
          break;
        default:
          pillBg = kGreyLight;
          pillText = kTextSecondary;
      }
    }

    final content = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proprietaire (si liste publique)
          if (proprietaire != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: kOrangeLight,
                  child: Text(
                    '${(proprietaire!['prenom'] as String? ?? '?')[0]}'.toUpperCase(),
                    style: const TextStyle(color: kOrange, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${proprietaire!['prenom'] ?? ''} ${proprietaire!['nom'] ?? ''}'.trim(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextPrimary),
                        ),
                      ),
                      if (proprietaire!['verifie'] == true) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: kGreen, size: 13),
                      ],
                    ],
                  ),
                ),
                if (niveau != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Compatible ${niveau.toUpperCase()}',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: pillText),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ] else if (niveau != null) ...[
            // Badge compatible seul (cas ou le proprietaire n'est pas affiche)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  'Compatible ${niveau.toUpperCase()}',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: pillText),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Statut + role (pour mes AD)
          if (proprietaire == null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _bgStatut(statut),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _libelleStatut(statut),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _textStatut(statut)),
                  ),
                ),
                Text(
                  isConducteur ? 'Conducteur' : 'Passager',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          // Trajet
          Row(
            children: [
              Icon(
                isConducteur ? Icons.directions_car_rounded : Icons.person_search_rounded,
                size: 18,
                color: kOrange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${ad['depart']} → ${ad['destination']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: barre ? TextDecoration.lineThrough : null,
                    color: barre ? kTextSecondary : kTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              '${ad['dateDeplacement']} · ${ad['heureDepart']}'
              '${isConducteur ? ' · ${ad['moyenTransport'] ?? ''} · ${ad['placesDisponibles']} place(s)' : ''}',
              style: TextStyle(fontSize: 11, color: kTextSecondary),
            ),
          ),
          // Distance / duree (pas de mini-carte dans la liste)
          if (distanceKm != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.route_rounded, size: 14, color: kOrange),
                const SizedBox(width: 4),
                Text(
                  '≈ ${distanceKm!.toStringAsFixed(1)} km'
                  '${dureeMinutes != null ? ' · ≈ $dureeMinutes min' : ''}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kOrange),
                ),
                if (proximiteKm != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.near_me_rounded, size: 13, color: kTextSecondary),
                  const SizedBox(width: 3),
                  Text(
                    'Départ à ~${(proximiteKm! * 1000).round()} m',
                    style: TextStyle(fontSize: 10, color: kTextSecondary),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );

    final wrapped = archive
        ? Opacity(opacity: 0.6, child: content)
        : content;

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: wrapped);
    }
    return wrapped;
  }

  String _libelleStatut(String statut) {
    switch (statut) {
      case 'actif':
        return 'ACTIF';
      case 'en_cours_de_finalisation':
        return 'EN COURS';
      case 'trajet_organise':
        return 'ORGANISÉ';
      case 'annule':
        return 'ANNULÉ';
      default:
        return statut.toUpperCase();
    }
  }

  Color _bgStatut(String statut) {
    switch (statut) {
      case 'actif':
        return kGreenLight;
      case 'en_cours_de_finalisation':
        return const Color(0xFFFFE8D4);
      case 'trajet_organise':
        return kGreen;
      default:
        return kGreyLight;
    }
  }

  Color _textStatut(String statut) {
    switch (statut) {
      case 'actif':
        return kGreen;
      case 'en_cours_de_finalisation':
        return const Color(0xFFB35A00);
      case 'trajet_organise':
        return Colors.white;
      default:
        return kTextSecondary;
    }
  }
}
