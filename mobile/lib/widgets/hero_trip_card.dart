import 'package:flutter/material.dart';
import '../main.dart';
import '../services/carte_service.dart';
import '../services/trip_selection.dart';
import '../widgets/mini_trajet_map.dart';
import 'package:latlong2/latlong.dart';

/// Statut lisible avec couleur (dupliqué ici pour garder trip_selection.dart pur).
class StatutInfo {
  final String libelle;
  final Color bg;
  final Color text;
  const StatutInfo(this.libelle, this.bg, this.text);
}

StatutInfo infoStatut(String statut) {
  switch (statut) {
    case 'trajet_organise':
      return const StatutInfo('Confirmé', kGreenLight, kGreen);
    case 'en_cours_de_finalisation':
      return const StatutInfo('En attente', Color(0xFFFFE8D4), Color(0xFFB35A00));
    case 'actif':
      return const StatutInfo('En attente', Color(0xFFFFE8D4), Color(0xFFB35A00));
    default:
      return StatutInfo(statut.toUpperCase(), kGreyLight, kTextSecondary);
  }
}

/// Carte « Trajet en vedette » : un seul trajet, en haut de l'accueil.
/// Contient pastille date/role, titre, mini-carte réelle (non interactive),
/// distance/durée, statut, action principale et menu ⋮.
class HeroTripCard extends StatefulWidget {
  final TrajetEnVedetteResult vedette;
  final String userId;
  final String prenom;
  final VoidCallback onDetail;
  final VoidCallback onModifier;
  final VoidCallback onAnnuler;
  final VoidCallback onVoirCompatibles;
  final VoidCallback onVoirDemande;
  final VoidCallback onDiscuter;

  const HeroTripCard({
    super.key,
    required this.vedette,
    required this.userId,
    required this.prenom,
    required this.onDetail,
    required this.onModifier,
    required this.onAnnuler,
    required this.onVoirCompatibles,
    required this.onVoirDemande,
    required this.onDiscuter,
  });

  Map<String, dynamic> get t => vedette.trajet;

  @override
  State<HeroTripCard> createState() => _HeroTripCardState();
}

class _HeroTripCardState extends State<HeroTripCard> {
  ItineraireInfo? _iti;
  bool _mapChargement = true;

  @override
  void initState() {
    super.initState();
    _chargerItineraire();
  }

  Future<void> _chargerItineraire() async {
    final depLat = (widget.t['departLat'] as num?)?.toDouble();
    final depLng = (widget.t['departLng'] as num?)?.toDouble();
    final arrLat = (widget.t['arriveeLat'] as num?)?.toDouble();
    final arrLng = (widget.t['arriveeLng'] as num?)?.toDouble();
    if (depLat != null && depLng != null && arrLat != null && arrLng != null) {
      try {
        final iti = await CarteService.calculerItineraire(
          LatLng(depLat, depLng),
          LatLng(arrLat, arrLng),
        );
        if (mounted) {
          setState(() {
            _iti = iti;
            _mapChargement = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _mapChargement = false);
      }
    } else {
      if (mounted) setState(() => _mapChargement = false);
    }
  }

  Map<String, dynamic> get t => widget.t;
  TrajetEnVedetteResult get vedette => widget.vedette;
  String get contexte => vedette.contexte;

  @override
  Widget build(BuildContext context) {
    final statutInfo = infoStatut(t['statut'] as String? ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pastille date + rôle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kOrangeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dateRelative(
                    t['dateDeplacement'] as String,
                    t['heureDepart'] as String,
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: kOrange,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kGreyLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  libelleRole(t['role'] as String?),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: kTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Titre : Départ → Arrivée (courts)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: kOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${adresseCourte(t['depart'] as String)} → ${adresseCourte(t['destination'] as String)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sousTitreTrajet(t),
                      style: TextStyle(
                        fontSize: 11,
                        color: kTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Mini-carte réelle (non interactive, 62×46 dp)
              GestureDetector(
                onTap: widget.onDetail,
                child: Container(
                  width: 62,
                  height: 46,
                  decoration: BoxDecoration(
                    color: kGreyLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _mapChargement
                      ? const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kOrange,
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: MiniTrajetMap(
                            ad: t,
                            height: 46,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Distance / durée (calculée réellement)
          if (_iti != null) ...[
            Row(
              children: [
                const Icon(Icons.route_rounded, size: 14, color: kOrange),
                const SizedBox(width: 4),
                Text(
                  '${CarteService.formaterDistance(_iti!.distanceKm)} · ${CarteService.formaterDuree(_iti!.dureeMinutes)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Ligne de statut avec point coloré
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statutInfo.text,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _libelleStatutContexte(contexte, statutInfo.libelle, t),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statutInfo.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action principale
          SizedBox(
            width: double.infinity,
            height: 46,
            child: _boutonPrincipal(contexte),
          ),
          const SizedBox(height: 10),

          // +N autre(s) trajet(s) le même jour
          if (vedette.nbAutresMemeJour > 0) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '+${vedette.nbAutresMemeJour} autre(s) trajet(s)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kTextSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Menu ⋮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: kGreyLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: kTextSecondary,
                    size: 20,
                  ),
                  onPressed: () => _ouvrirMenu(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _boutonPrincipal(String contexte) {
    switch (contexte) {
      case 'confirme':
        return FilledButton.icon(
          onPressed: widget.onDiscuter,
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: Text(
            'Discuter avec ${vedette.partenairePrenom ?? 'ton partenaire'}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: kOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      case 'sans_partenaire':
        final role = t['role'] as String?;
        if (role == 'conducteur') {
          return OutlinedButton.icon(
            onPressed: widget.onVoirCompatibles,
            icon: const Icon(Icons.explore_rounded, size: 18, color: kOrange),
            label: const Text(
              'Voir les trajets compatibles',
              style: TextStyle(color: kOrange, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kOrange.withAlpha(120)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      case 'en_attente':
        return OutlinedButton.icon(
          onPressed: widget.onVoirDemande,
          icon: const Icon(Icons.assignment_rounded, size: 18, color: kOrange),
          label: const Text(
            'Voir la demande',
            style: TextStyle(color: kOrange, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: kOrange.withAlpha(120)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _libelleStatutContexte(
    String contexte,
    String libelleStatut,
    Map<String, dynamic> t,
  ) {
    switch (contexte) {
      case 'confirme':
        final prenom = vedette.partenairePrenom ?? '';
        final places = t['placesDisponibles'] as int?;
        return 'Confirmé avec $prenom · ${places ?? 0} place${places != null && places > 1 ? 's' : ''} restante(s)';
      case 'en_attente':
        final prenom = vedette.partenairePrenom ?? '';
        if (prenom.isNotEmpty) {
          return 'En attente de la réponse de $prenom';
        }
        return 'En attente de partenaires · ${t['placesDisponibles'] ?? 0} place(s)';
      case 'sans_partenaire':
        return 'En attente de partenaires · ${t['placesDisponibles'] ?? 0} place(s)';
      default:
        return libelleStatut;
    }
  }

  void _ouvrirMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: kTextSecondary),
              title: const Text('Voir le détail'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onDetail();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: kTextSecondary),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onModifier();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: kRed),
              title: const Text(
                'Annuler le trajet',
                style: TextStyle(color: kRed, fontWeight: FontWeight.w700),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmerAnnulation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmerAnnulation(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Annuler le trajet ?'),
        content: const Text(
          'Ton trajet ne sera plus visible. '
          'Si un partenaire a confirmé, il sera prévenu de l’annulation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui, annuler', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
    if (confirme == true) {
      widget.onAnnuler();
    }
  }
}
