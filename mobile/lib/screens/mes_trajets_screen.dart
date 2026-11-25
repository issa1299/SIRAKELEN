import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/trip_selection.dart';
import '../widgets/carte_ad.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/skeleton_loader.dart';
import 'publier_screen.dart';

// Ecran lourd charge a la demande.
import 'detail_ad_screen.dart' deferred as detailDeferred;

/// Nouvel écran « Mes trajets » avec 3 onglets :
/// - À venir : tous les trajets à venir (non annulés, date future)
/// - Demandes : demandes envoyées et reçues avec leur statut
/// - Passés : terminés, annulés, expirés, refusés (atténués)
class MesTrajetsScreen extends StatefulWidget {
  final String userId;
  final int initialTab; // 0 = À venir, 1 = Demandes, 2 = Passés

  const MesTrajetsScreen({
    super.key,
    required this.userId,
    this.initialTab = 0,
  });

  @override
  State<MesTrajetsScreen> createState() => _MesTrajetsScreenState();
}

class _MesTrajetsScreenState extends State<MesTrajetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _trajets = [];
  List<Map<String, dynamic>> _demandesRecues = [];
  List<Map<String, dynamic>> _demandesEnvoyees = [];
  String _filtreRole = 'tous'; // 'tous', 'conducteur', 'passager'
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _charger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    if (widget.userId.isEmpty) {
      setState(() => _chargement = false);
      return;
    }
    try {
      final [trajets, recues, envoyees] = await Future.wait([
        ApiService.mesAds(widget.userId),
        ApiService.getDemandesRecues(widget.userId),
        ApiService.getDemandesEnvoyees(widget.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _trajets = List<Map<String, dynamic>>.from(trajets);
        _demandesRecues = List<Map<String, dynamic>>.from(recues);
        _demandesEnvoyees = List<Map<String, dynamic>>.from(envoyees);
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Connexion au serveur impossible';
        _chargement = false;
      });
    }
  }

  Future<void> _refresh() => _charger();

  /// Liste des trajets « À venir » (date >= aujourd'hui, statut != annulé)
  List<Map<String, dynamic>> get _trajetsAVenir {
    final aujourdhui = DateTime.now();
    final aujourdhuiJour =
        DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);

    return _trajets.where((t) {
      final statut = t['statut'] as String? ?? '';
      if (statut == 'annule') return false;
      final dateStr = t['dateDeplacement'] as String? ?? '';
      if (dateStr.isEmpty) return false;
      final parts = dateStr.split('-');
      if (parts.length < 3) return false;
      final d = DateTime(
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
        int.tryParse(parts[2]) ?? 0,
      );
      if (d.isBefore(aujourdhuiJour)) return false;

      // Filtre par rôle
      if (_filtreRole != 'tous') {
        final role = t['role'] as String? ?? '';
        if (role != _filtreRole) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final da = a['dateDeplacement'] as String? ?? '';
        final db = b['dateDeplacement'] as String? ?? '';
        var cmp = da.compareTo(db);
        if (cmp != 0) return cmp;
        return (a['heureDepart'] as String? ?? '')
            .compareTo(b['heureDepart'] as String? ?? '');
      });
  }

  /// Liste des trajets « Passés » (annulé ou date passée)
  List<Map<String, dynamic>> get _trajetsPasses {
    final aujourdhui = DateTime.now();
    final aujourdhuiJour =
        DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);

    return _trajets.where((t) {
      final statut = t['statut'] as String? ?? '';
      if (statut == 'annule') return true;
      final dateStr = t['dateDeplacement'] as String? ?? '';
      if (dateStr.isEmpty) return false;
      final parts = dateStr.split('-');
      if (parts.length < 3) return false;
      final d = DateTime(
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
        int.tryParse(parts[2]) ?? 0,
      );
      return d.isBefore(aujourdhuiJour);
    }).toList()
      ..sort((a, b) {
        final da = a['dateDeplacement'] as String? ?? '';
        final db = b['dateDeplacement'] as String? ?? '';
        return db.compareTo(da); // plus récent d'abord
      });
  }

  /// Toutes les demandes (reçues + envoyées) avec le trajet associé
  List<Map<String, dynamic>> get _toutesDemandes {
    final result = <Map<String, dynamic>>[];

    for (final d in _demandesRecues) {
      result.add({
        ...d,
        'type': 'recue',
        'ad': d['ad'] as Map<String, dynamic>?,
        'autreNom':
            '${(d['demandeur'] as Map<String, dynamic>?)?['prenom'] ?? ''} ${(d['demandeur'] as Map<String, dynamic>?)?['nom'] ?? ''}',
      });
    }
    for (final d in _demandesEnvoyees) {
      result.add({
        ...d,
        'type': 'envoyee',
        'ad': d['ad'] as Map<String, dynamic>?,
        'autreNom':
            '${(d['proprietaire'] as Map<String, dynamic>?)?['prenom'] ?? ''} ${(d['proprietaire'] as Map<String, dynamic>?)?['nom'] ?? ''}',
      });
    }

    result.sort((a, b) {
      final ca = a['creeLe'] as String? ?? '';
      final cb = b['creeLe'] as String? ?? '';
      return cb.compareTo(ca);
    });

    return result;
  }

  String _statutDemandeLibelle(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'acceptee':
        return 'Acceptée';
      case 'refusee':
        return 'Refusée';
      case 'annulee':
        return 'Annulée';
      default:
        return statut.toUpperCase();
    }
  }

  Color _statutDemandeCouleur(String statut) {
    switch (statut) {
      case 'acceptee':
        return kGreen;
      case 'en_attente':
        return const Color(0xFFB35A00);
      case 'refusee':
      case 'annulee':
        return kRed;
      default:
        return kTextSecondary;
    }
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

  Widget _chipFiltre(String label, String valeur) {
    final selected = _filtreRole == valeur;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : kTextSecondary,
        ),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _filtreRole = valeur),
      selectedColor: kOrange,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? kOrange : kBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  Widget _etatVide(String titre, String sousTitre, IconData icon,
      {bool publier = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kGreyLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: kTextSecondary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              titre,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sousTitre,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kTextSecondary, height: 1.5),
            ),
            if (publier) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublierScreen(userId: widget.userId),
                      ),
                    );
                    _charger();
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Publier un trajet'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ongletAVenir() {
    final trajets = _trajetsAVenir;
    if (trajets.isEmpty) {
      return _etatVide(
        'Aucun trajet à venir',
        'Publiez votre prochain déplacement.',
        Icons.route_rounded,
        publier: true,
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      color: kOrange,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Filtres rapides
          Row(
            children: [
              const SizedBox(width: 4),
              _chipFiltre('Tous', 'tous'),
              const SizedBox(width: 8),
              _chipFiltre('Conducteur', 'conducteur'),
              const SizedBox(width: 8),
              _chipFiltre('Passager', 'passager'),
            ],
          ),
          const SizedBox(height: 12),
          ...trajets.map((t) {
            final estOrganise = t['statut'] == 'trajet_organise';
            final estAnnule = t['statut'] == 'annule';
            return CarteAd(
              ad: t,
              archive: estAnnule,
              onTap: estOrganise || estAnnule
                  ? null
                  : () {
                      detailDeferred.loadLibrary().then((_) {
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
                      });
                    },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _ongletDemandes() {
    final demandes = _toutesDemandes;
    if (demandes.isEmpty) {
      return _etatVide(
        'Aucune demande',
        'Vos demandes apparaissent ici.',
        Icons.assignment_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      color: kOrange,
      child: ListView.builder(
        itemCount: demandes.length,
        padding: const EdgeInsets.all(20),
        itemBuilder: (ctx, i) {
          final d = demandes[i];
          final ad = d['ad'] as Map<String, dynamic>?;
          return _ligneDemande(d, ad);
        },
      ),
    );
  }

  Widget _ongletPasses() {
    final trajets = _trajetsPasses;
    if (trajets.isEmpty) {
      return _etatVide(
        'Aucun trajet passé',
        'Vos trajets terminés apparaissent ici.',
        Icons.history_rounded,
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      color: kOrange,
      child: ListView.builder(
        itemCount: trajets.length,
        padding: const EdgeInsets.all(20),
        itemBuilder: (ctx, i) {
          final t = trajets[i];
          return CarteAd(
            ad: t,
            archive: true,
            onTap: () {
              detailDeferred.loadLibrary().then((_) {
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
              });
            },
          );
        },
      ),
    );
  }

  Widget _ligneDemande(Map<String, dynamic> d, Map<String, dynamic>? ad) {
    final statut = d['statut'] as String? ?? '';
    final couleur = _statutDemandeCouleur(statut);
    final libelle = _statutDemandeLibelle(statut);
    final autreNom = d['autreNom'] as String? ?? '';
    final type = d['type'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: kGreyLight,
            child: Text(
              autreNom.isNotEmpty ? autreNom[0].toUpperCase() : '?',
              style: const TextStyle(
                color: kTextSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == 'recue'
                      ? 'Demande de $autreNom'
                      : 'Demande envoyée à $autreNom',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                if (ad != null)
                  Text(
                    '${ad['depart']} → ${ad['destination']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: kTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: couleur.withAlpha(60),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              libelle,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: couleur,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList(int count) {
    return ListView.builder(
      itemCount: count,
      padding: const EdgeInsets.all(20),
      itemBuilder: (_, __) => const SkeletonTripCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        title: const Text('Mes trajets'),
        elevation: 0,
        backgroundColor: kCream,
        foregroundColor: kTextPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kOrange,
          labelColor: kOrange,
          unselectedLabelColor: kTextSecondary,
          tabs: const [
            Tab(text: 'À venir'),
            Tab(text: 'Demandes'),
            Tab(text: 'Passés'),
          ],
        ),
      ),
      body: ResponsiveWrapper(
        child: _chargement
            ? _buildSkeletonList(6)
            : _erreur != null
                ? _etatErreur()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _ongletAVenir(),
                      _ongletDemandes(),
                      _ongletPasses(),
                    ],
                  ),
      ),
    );
  }
}
