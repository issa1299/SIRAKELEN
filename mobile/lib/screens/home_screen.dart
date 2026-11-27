import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/notification_read_service.dart';
import '../services/trip_selection.dart';
import '../widgets/empty_home.dart';
import '../widgets/hero_trip_card.dart';
import '../widgets/my_trips_link.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/todo_section.dart';
import 'mes_trajets_screen.dart';
import 'notifications_screen.dart';
import 'parcourir_ads_screen.dart';

// Ecrans lourds charges a la demande (deferred loading).
import 'chat_screen.dart' deferred as chatDeferred;
import 'detail_ad_screen.dart' deferred as detailDeferred;
import 'profil_autre_screen.dart' deferred as profilAutreDeferred;

/// Écran Accueil allégé : « quoi faire maintenant ».
///
/// Blocs verticaux uniquement :
/// 1. En-tête (date, bonjour, cloche avec badge « À traiter »)
/// 2. Carte « Trajet en vedette » (un seul trajet)
/// 3. Section « À traiter » (2 lignes max, masquée si vide)
/// 4. Ligne « Tous mes trajets »
///
/// État vide si aucun trajet à venir.
class HomeScreen extends StatefulWidget {
  final String prenom;
  final String userId;
  const HomeScreen({super.key, this.prenom = '', this.userId = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _trajets = [];
  List<Map<String, dynamic>> _demandesRecues = [];
  int _nbNonLus = 0;
  bool _chargement = true;
  String? _erreur;
  TrajetEnVedetteResult? _vedette;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    if (widget.userId.isEmpty) {
      setState(() => _chargement = false);
      return;
    }
    try {
      final [trajets, recues] = await Future.wait([
        ApiService.mesAds(widget.userId),
        ApiService.getDemandesRecues(widget.userId),
      ]);
      if (!mounted) return;
      final maintenant = DateTime.now();
      TrajetEnVedetteResult? vedette;
      try {
        vedette = choisirTrajetEnVedette(
          List<Map<String, dynamic>>.from(trajets),
          List<Map<String, dynamic>>.from(recues),
          maintenant,
        );
      } catch (_) {
        vedette = null; // aucun trajet à venir
      }
      setState(() {
        _trajets = List<Map<String, dynamic>>.from(trajets);
        _demandesRecues =
            List<Map<String, dynamic>>.from(recues)
                .where((d) => d['statut'] == 'en_attente')
                .toList();
        _vedette = vedette;
        _chargement = false;
      });
      final nonLues =
          await NotificationReadService.nonLues(_demandesRecues);
      if (mounted) setState(() => _nbNonLus = nonLues.length);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Connexion au serveur impossible';
        _chargement = false;
      });
    }
  }

  Future<void> _refresh() => _charger();

  Future<void> _ouvrirChat({
    required String demandeId,
    required String partenaireNom,
    required String trajetLabel,
  }) async {
    await chatDeferred.loadLibrary();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => chatDeferred.ChatScreen(
          demandeId: demandeId,
          userId: widget.userId,
          partenaireNom: partenaireNom,
          trajetLabel: trajetLabel,
        ),
      ),
    );
  }

  String _dateJour() {
    final m = DateTime.now();
    const jours = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche',
    ];
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août',
      'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${jours[m.weekday - 1]} ${m.day} ${mois[m.month - 1]}';
  }

  int get _nbATraiter => _nbNonLus;

  Widget _sectionTitle(String title, {int? count}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
              ),
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kOrangeLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: kOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _boutonMenuPlus(BuildContext context, Map<String, dynamic> t) {
    return Container(
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
        onPressed: () => _ouvrirMenu(context, t),
      ),
    );
  }

  void _ouvrirMenu(BuildContext context, Map<String, dynamic> t) {
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
              onTap: () async {
                Navigator.pop(ctx);
                await detailDeferred.loadLibrary();
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => detailDeferred.DetailAdScreen(
                      adId: t['id'] as String,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: kTextSecondary),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(ctx);
                // TODO: ouvrir écran de modification du trajet
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
                _confirmerAnnulation(context, t);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmerAnnulation(
      BuildContext context, Map<String, dynamic> t) async {
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
      try {
        await ApiService.annulerAd(t['id'] as String, widget.userId);
        await _charger();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final historiqueNonVide = _trajets.any((t) {
      final statut = t['statut'] as String? ?? '';
      final dateStr = t['dateDeplacement'] as String? ?? '';
      if (statut == 'annule') return true;
      if (dateStr.isEmpty) return false;
      final parts = dateStr.split('-');
      if (parts.length < 3) return false;
      final d = DateTime(
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
        int.tryParse(parts[2]) ?? 0,
      );
      final aujourdhui = DateTime.now();
      final aujourdhuiJour =
          DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
      return statut == 'annule' || d.isBefore(aujourdhuiJour);
    });

    return Scaffold(
      backgroundColor: kCream,
      body: ResponsiveWrapper(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: kOrange,
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // ===== En-tête =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dateJour(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kOrange,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.prenom.isEmpty
                            ? 'Bonjour'
                            : 'Bonjour, ${widget.prenom}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationsScreen(
                            userId: widget.userId,
                          ),
                        ),
                      );
                      _charger();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: kOrange,
                          ),
                        ),
                        if (_nbATraiter > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: kRed,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_nbATraiter',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Accès permanent à tous les trajets disponibles.
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParcourirAdsScreen(userId: widget.userId),
                  ),
                ),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: kOrangeLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.explore_rounded,
                            color: kOrange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Parcourir tous les trajets disponibles',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: kTextSecondary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ===== Chargement / Erreur =====
              if (_chargement) ...[
                const SkeletonHeader(),
                const SizedBox(height: 24),
                const SkeletonTripCard(),
                const SizedBox(height: 24),
                const SkeletonTripCard(),
              ] else if (_erreur != null)
                _etatErreur()
              else if (_vedette != null) ...[
                // ===== Carte « Trajet en vedette » =====
                HeroTripCard(
                  vedette: _vedette!,
                  userId: widget.userId,
                  prenom: widget.prenom,
                  onDetail: () async {
                    await detailDeferred.loadLibrary();
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => detailDeferred.DetailAdScreen(
                          adId: _vedette!.trajet['id'] as String,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                  onModifier: () async {
                    await detailDeferred.loadLibrary();
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => detailDeferred.DetailAdScreen(
                          adId: _vedette!.trajet['id'] as String,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                  onAnnuler: () =>
                      _confirmerAnnulation(context, _vedette!.trajet),
                  onVoirCompatibles: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParcourirAdsScreen(
                        userId: widget.userId,
                        departDefaut:
                            _vedette!.trajet['depart'] as String?,
                        destinationDefaut:
                            _vedette!.trajet['destination'] as String?,
                      ),
                    ),
                  ),
                  onVoirDemande: () => _tabDemandes(),
                  onDiscuter: () {
                    if (_vedette!.partenaire != null &&
                        _vedette!.partenairePrenom != null) {
                      _ouvrirChat(
                        demandeId: _vedette!.demandeId ?? '',
                        partenaireNom:
                            '${_vedette!.partenaire!['prenom'] ?? ''} ${_vedette!.partenaire!['nom'] ?? ''}',
                        trajetLabel:
                            '${_vedette!.trajet['depart']} → ${_vedette!.trajet['destination']}',
                      );
                    }
                  },
                ),

                // ===== Section « À traiter » =====
                TodoSection(
                  demandesRecues: _demandesRecues,
                  nbMessagesNonLus: 0,
                  userId: widget.userId,
                  onRepondre: _tabDemandes,
                  onVoirNotifications: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                ),

                // ===== Ligne « Tous mes trajets » =====
                MyTripsLink(
                  userId: widget.userId,
                  historiqueNonVide: historiqueNonVide,
                ),
              ] else ...[
                // ===== État vide =====
                EmptyHome(
                  userId: widget.userId,
                  historiqueNonVide: historiqueNonVide,
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _etatErreur() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: kTextSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              _erreur ?? 'Erreur',
              style: TextStyle(color: kTextSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _refresh,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  void _tabDemandes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MesTrajetsScreen(
          userId: widget.userId,
          initialTab: 1,
        ),
      ),
    );
  }
}
