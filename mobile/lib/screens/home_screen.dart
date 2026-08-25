import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'publier_screen.dart';

class HomeScreen extends StatefulWidget {
  final String prenom;
  final String userId;
  const HomeScreen({super.key, this.prenom = '', this.userId = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _adActif;
  List<dynamic> _compatibilites = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerMonAd();
  }

  Future<void> _chargerMonAd() async {
    if (widget.userId.isEmpty) {
      setState(() => _chargement = false);
      return;
    }
    try {
      final ads = await ApiService.mesAds(widget.userId);
      final actifs = ads
          .where((a) =>
              a['statut'] == 'actif' ||
              a['statut'] == 'en_cours_de_finalisation')
          .toList();
      List<dynamic> comps = [];
      if (actifs.isNotEmpty) {
        comps = await ApiService.getCompatibilites(widget.userId);
      }
      if (!mounted) return;
      setState(() {
        _adActif =
            actifs.isNotEmpty ? actifs.first as Map<String, dynamic> : null;
        _compatibilites = comps;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _annulerAd() async {
    if (_adActif == null) return;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler cet AD ?'),
        content: const Text(
            'Ton trajet ne sera plus visible par les autres utilisateurs.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Oui, annuler',
                  style: TextStyle(color: Color(0xFFA3392F)))),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await ApiService.annulerAd(_adActif!['id'] as String, widget.userId);
      await _chargerMonAd();
    } catch (_) {}
  }

  String _libelleStatut(String statut) {
    switch (statut) {
      case 'actif':
        return 'ACTIF';
      case 'en_cours_de_finalisation':
        return 'EN COURS DE FINALISATION';
      case 'trajet_organise':
        return 'TRAJET ORGANISÉ';
      default:
        return statut.toUpperCase();
    }
  }

  Widget _carteCompatibilite(Map<String, dynamic> comp) {
    final niveau = comp['niveau'] as String;
    Color pillBg;
    Color pillText;
    String label;
    switch (niveau) {
      case 'fort':
        pillBg = kGreen;
        pillText = Colors.white;
        label = 'FORT';
        break;
      case 'moyen':
        pillBg = const Color(0xFFFFE8D4);
        pillText = const Color(0xFFB35A00);
        label = 'MOYEN';
        break;
      default:
        pillBg = Colors.white;
        pillText = Colors.grey.shade600;
        label = 'FAIBLE';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEAE2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: const Color(0xFFFFF3E6),
            child: Icon(Icons.person, color: kOrangeDark, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(comp['nom'] as String,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800)),
                    ),
                    if (comp['verifie'] == true) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified,
                          color: kGreen, size: 13),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${comp['depart']} → ${comp['destination']} · ${comp['heure']}',
                  style:
                      TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(20),
              border: niveau == 'faible'
                  ? Border.all(color: const Color(0xFFEDEAE2))
                  : null,
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    color: pillText)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _chargerMonAd,
          color: kOrange,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BONJOUR',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade500,
                              letterSpacing: 0.8)),
                      Text(
                          widget.prenom.isEmpty
                              ? '👋'
                              : '${widget.prenom} 👋',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child:
                        Icon(Icons.notifications_none, color: kOrange),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_chargement)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                      child: CircularProgressIndicator(color: kOrange)),
                )
              else if (_adActif != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFDFC0), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('MON AD ACTIF',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Colors.grey.shade500)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: _adActif!['statut'] == 'actif'
                                  ? const Color(0xFFE2F2E5)
                                  : const Color(0xFFFFE8D4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _libelleStatut(_adActif!['statut'] as String),
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                color: _adActif!['statut'] == 'actif'
                                    ? const Color(0xFF125A1E)
                                    : const Color(0xFFB35A00),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.route, color: kOrange, size: 17),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              '${_adActif!['depart']} → ${_adActif!['destination']}',
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_adActif!['dateDeplacement']} à ${_adActif!['heureDepart']}'
                        '${_adActif!['role'] == 'conducteur' ? ' · ${_adActif!['moyenTransport']} · ${_adActif!['placesDisponibles']} place(s)' : ''}',
                        style: TextStyle(
                            fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _annulerAd,
                          child: const Text('Annuler cet AD',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFA3392F),
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_compatibilites.isNotEmpty) ...[
                  Text(
                    '${_compatibilites.length} compatibilité${_compatibilites.length > 1 ? 's' : ''} trouvée${_compatibilites.length > 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  ..._compatibilites.map(
                      (c) => _carteCompatibilite(c as Map<String, dynamic>)),
                ] else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEDEAE2)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.refresh,
                            color: Colors.grey.shade400, size: 28),
                        const SizedBox(height: 8),
                        const Text('Aucune compatibilité pour l’instant',
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Text(
                          'Ton AD reste actif. Tu seras prévenu dès qu’un trajet compatible est trouvé.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    _adActif!['role'] == 'conducteur'
                        ? 'Recherche de passagers compatibles…'
                        : 'Recherche de conducteurs compatibles…',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFDFC0)),
                        ),
                        child: const Icon(Icons.route,
                            color: kOrange, size: 34),
                      ),
                      const SizedBox(height: 16),
                      const Text('Aucun trajet publié',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                        'Publiez votre premier Avis de Déplacement pour découvrir des trajets compatibles près de chez vous.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
              FilledButton.icon(
                onPressed: widget.userId.isEmpty
                    ? null
                    : () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PublierScreen(userId: widget.userId)),
                        );
                        _chargerMonAd();
                      },
                icon: const Icon(Icons.add),
                label: const Text('Publier un AD'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
