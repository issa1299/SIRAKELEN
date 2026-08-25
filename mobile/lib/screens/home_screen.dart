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
  List<dynamic> _demandesRecues = [];
  List<dynamic> _demandesEnvoyees = [];
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
      List<dynamic> recues = [];
      List<dynamic> envoyees = [];
      if (actifs.isNotEmpty || ads.isNotEmpty) {
        comps = actifs.isNotEmpty
            ? await ApiService.getCompatibilites(widget.userId)
            : [];
        recues = await ApiService.getDemandesRecues(widget.userId);
        envoyees = await ApiService.getDemandesEnvoyees(widget.userId);
      }
      if (!mounted) return;
      setState(() {
        _adActif =
            actifs.isNotEmpty ? actifs.first as Map<String, dynamic> : null;
        _compatibilites = comps;
        _demandesRecues =
            recues.where((d) => d['statut'] == 'en_attente').toList();
        _demandesEnvoyees = envoyees;
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

  Future<void> _envoyerInteret(Map<String, dynamic> comp) async {
    try {
      await ApiService.envoyerDemande(
          comp['adId'] as String, widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande envoyée ! Tu pourras suivre la réponse ici.'),
          backgroundColor: kGreen,
        ),
      );
      await _chargerMonAd();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: kOrangeDark));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Connexion au serveur impossible'),
          backgroundColor: Color(0xFFA3392F)));
    }
  }

  Widget _carteDemandeEnvoyee(Map<String, dynamic> d) {
    final ad = d['ad'] as Map<String, dynamic>;
    final proprietaire = ad['proprietaire'] as Map<String, dynamic>;
    final statut = d['statut'] as String;

    String label;
    Color bg;
    Color text;
    switch (statut) {
      case 'en_attente':
        label = 'EN ATTENTE';
        bg = const Color(0xFFFFE8D4);
        text = const Color(0xFFB35A00);
        break;
      case 'acceptee':
        label = 'ACCEPTÉE ✓';
        bg = kGreen;
        text = Colors.white;
        break;
      case 'refusee':
        label = 'REFUSÉE';
        bg = const Color(0xFFFDECEA);
        text = const Color(0xFFA3392F);
        break;
      default:
        label = 'ANNULÉE';
        bg = const Color(0xFFEFEDE5);
        text = Colors.grey.shade600;
    }

    final acceptee = statut == 'acceptee';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEAE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${proprietaire['prenom']} ${proprietaire['nom']}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '${ad['depart']} → ${ad['destination']} · ${ad['heureDepart']}',
                      style: TextStyle(
                          fontSize: 10.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: text)),
              ),
            ],
          ),
          if (acceptee) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F2E5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.call, color: kGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coordonnées débloquées : appelle ${proprietaire['prenom']} au ${proprietaire['telephone']} ou via WhatsApp.',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF125A1E),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (statut == 'en_attente') ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  try {
                    await ApiService.annulerDemande(
                        d['id'] as String, widget.userId);
                    await _chargerMonAd();
                  } catch (_) {}
                },
                child: Text('Annuler ma demande',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _carteDemandeRecue(Map<String, dynamic> d) {
    final demandeur = d['demandeur'] as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEAE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFFFF3E6),
                child: Icon(Icons.person, color: kOrangeDark, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                              '${demandeur['prenom']} ${demandeur['nom']}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                        ),
                        if (demandeur['verifie'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              color: kGreen, size: 13),
                        ],
                      ],
                    ),
                    Text(
                        'veut rejoindre ton trajet ${d['ad']['depart']} → ${d['ad']['destination']}',
                        style: TextStyle(
                            fontSize: 10.5, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    try {
                      await ApiService.accepterDemande(
                          d['id'] as String, widget.userId);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Accepté ! Contacte ton partenaire par téléphone ou WhatsApp.'),
                          backgroundColor: kGreen));
                      await _chargerMonAd();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: const Color(0xFFA3392F)));
                    }
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Accepter'),
                  style: FilledButton.styleFrom(
                    backgroundColor: kGreen,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await ApiService.refuserDemande(
                          d['id'] as String, widget.userId);
                      await _chargerMonAd();
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Refuser'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: const BorderSide(color: Color(0xFFEDEAE2)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          Column(
            children: [
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
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _adActif != null &&
                        _adActif!['statut'] == 'en_cours_de_finalisation'
                    ? null
                    : () => _envoyerInteret(comp),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: kOrange,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('Intéressé',
                      style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
            ],
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
                      if (_adActif!['statut'] ==
                          'en_cours_de_finalisation') ...[
                        const SizedBox(height: 4),
                        FilledButton.icon(
                          onPressed: () async {
                            try {
                              await ApiService.marquerOrganise(
                                  _adActif!['id'] as String, widget.userId);
                              await _chargerMonAd();
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Marquer comme trajet organisé'),
                          style: FilledButton.styleFrom(
                            backgroundColor: kGreen,
                            minimumSize: const Size.fromHeight(44),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_demandesRecues.isNotEmpty) ...[
                  Text(
                    '${_demandesRecues.length} demande${_demandesRecues.length > 1 ? 's' : ''} reçue${_demandesRecues.length > 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  ..._demandesRecues.map(
                      (d) => _carteDemandeRecue(d as Map<String, dynamic>)),
                  const SizedBox(height: 12),
                ],
                if (_demandesEnvoyees.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'MES DEMANDES ENVOYÉES',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  ..._demandesEnvoyees.map(
                      (d) => _carteDemandeEnvoyee(d as Map<String, dynamic>)),
                ],
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
