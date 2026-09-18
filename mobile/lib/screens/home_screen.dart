import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/carte_service.dart';
import '../services/whatsapp_helper.dart';
import 'publier_screen.dart';
import 'profil_autre_screen.dart';

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
  Map<String, dynamic>? _partenaire;
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
        _partenaire = null;
        if (_adActif != null &&
            _adActif!['statut'] == 'en_cours_de_finalisation') {
          final acceptee = recues
              .where((d) => d['statut'] == 'acceptee')
              .toList();
          if (acceptee.isNotEmpty) {
            _partenaire =
                (acceptee.first['demandeur'] as Map<String, dynamic>?);
          }
        }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  style: TextStyle(color: kRed))),
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
          backgroundColor: kRed));
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: kTextSecondary,
        ),
      ),
    );
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
        label = 'ACCEPTÉE';
        bg = kGreenLight;
        text = kGreen;
        break;
      case 'refusee':
        label = 'REFUSÉE';
        bg = kRedLight;
        text = kRed;
        break;
      default:
        label = 'ANNULÉE';
        bg = kGreyLight;
        text = kTextSecondary;
    }

    final acceptee = statut == 'acceptee';
    return Container(
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
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilAutreScreen(
                      targetUserId: proprietaire['id'] as String,
                      viewerUserId: widget.userId,
                    ),
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: kOrangeLight,
                  backgroundImage: (proprietaire['photoUrl'] != null && (proprietaire['photoUrl'] as String).isNotEmpty)
                      ? NetworkImage('${ApiService.baseUrl}${proprietaire['photoUrl']}')
                      : null,
                  child: (proprietaire['photoUrl'] == null || (proprietaire['photoUrl'] as String).isEmpty)
                      ? Text(
                          '${proprietaire['prenom'][0]}',
                          style: const TextStyle(
                            color: kOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilAutreScreen(
                        targetUserId: proprietaire['id'] as String,
                        viewerUserId: widget.userId,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${proprietaire['prenom']} ${proprietaire['nom']}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ad['depart']} → ${ad['destination']} · ${ad['heureDepart']}',
                        style: TextStyle(fontSize: 11, color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
              ),
            ],
          ),
          if (acceptee) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await WhatsAppHelper.ouvrir(
                    telephone: '${proprietaire['telephone']}',
                    message: 'Bonjour ${proprietaire['prenom']}, je te contacte au sujet du trajet SIRA KELEN.',
                  );
                },
                icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Contacter ${proprietaire['prenom']} via WhatsApp',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
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
                child: Text(
                  'Annuler ma demande',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kTextSecondary,
                  ),
                ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilAutreScreen(
                      targetUserId: demandeur['id'] as String,
                      viewerUserId: widget.userId,
                    ),
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: kOrangeLight,
                  backgroundImage: (demandeur['photoUrl'] != null && (demandeur['photoUrl'] as String).isNotEmpty)
                      ? NetworkImage('${ApiService.baseUrl}${demandeur['photoUrl']}')
                      : null,
                  child: (demandeur['photoUrl'] == null || (demandeur['photoUrl'] as String).isEmpty)
                      ? Text(
                          '${demandeur['prenom'][0]}',
                          style: const TextStyle(
                            color: kOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilAutreScreen(
                        targetUserId: demandeur['id'] as String,
                        viewerUserId: widget.userId,
                      ),
                    ),
                  ),
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
                                fontWeight: FontWeight.w700,
                                color: kTextPrimary,
                              ),
                            ),
                          ),
                          if (demandeur['verifie'] == true) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: kGreen, size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'veut rejoindre ton trajet ${d['ad']['depart']} → ${d['ad']['destination']}',
                        style: TextStyle(fontSize: 11, color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Voir profil button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilAutreScreen(
                    targetUserId: demandeur['id'] as String,
                    viewerUserId: widget.userId,
                  ),
                ),
              ),
              child: Text(
                'Voir le profil →',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kOrange,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                          content: Text('Demande acceptée ! Contacte ton partenaire.'),
                          backgroundColor: kGreen));
                      await _chargerMonAd();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: kRed));
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Accepter'),
                  style: FilledButton.styleFrom(
                    backgroundColor: kGreen,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await ApiService.refuserDemande(
                          d['id'] as String, widget.userId);
                      await _chargerMonAd();
                    } catch (_) {}
                  },
                  icon: Icon(Icons.close_rounded, size: 18, color: kTextSecondary),
                  label: Text('Refuser', style: TextStyle(color: kTextSecondary)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kTextSecondary,
                    side: const BorderSide(color: kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
    final myRole = _adActif?['role'] as String?;
    final theirRole = comp['role'] as String?;
    Color pillBg;
    Color pillText;
    String label;
    switch (niveau) {
      case 'fort':
        pillBg = kGreenLight;
        pillText = kGreen;
        label = 'FORT';
        break;
      case 'moyen':
        pillBg = const Color(0xFFFFE8D4);
        pillText = const Color(0xFFB35A00);
        label = 'MOYEN';
        break;
      default:
        pillBg = kGreyLight;
        pillText = kTextSecondary;
        label = 'FAIBLE';
    }

    // GPS coords
    final double? theirDepLat = (comp['departLat'] as num?)?.toDouble();
    final double? theirDepLng = (comp['departLng'] as num?)?.toDouble();
    final double? theirArrLat = (comp['arriveeLat'] as num?)?.toDouble();
    final double? theirArrLng = (comp['arriveeLng'] as num?)?.toDouble();
    final bool hasGps = theirDepLat != null && theirDepLng != null && theirArrLat != null && theirArrLng != null;

    // Determine itinerary type
    bool isDetour = false;
    if (myRole == 'conducteur' && theirRole == 'passager') {
      isDetour = true;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilAutreScreen(
            targetUserId: comp['userId'] as String,
            viewerUserId: widget.userId,
          ),
        ),
      ),
      child: Container(
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
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kOrangeLight,
                  backgroundImage: (comp['photoUrl'] != null && (comp['photoUrl'] as String).isNotEmpty)
                      ? NetworkImage('${ApiService.baseUrl}${comp['photoUrl']}')
                      : null,
                  child: (comp['photoUrl'] == null || (comp['photoUrl'] as String).isEmpty)
                      ? Text(
                          '${(comp['nom'] as String).split(' ').first[0]}',
                          style: const TextStyle(
                            color: kOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              comp['nom'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kTextPrimary,
                              ),
                            ),
                          ),
                          if (comp['verifie'] == true) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: kGreen, size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${comp['depart']} → ${comp['destination']} · ${comp['heure']}',
                        style: TextStyle(fontSize: 11, color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(20),
                        border: niveau == 'faible'
                            ? Border.all(color: kBorder)
                            : null,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: pillText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _adActif != null &&
                              _adActif!['statut'] == 'en_cours_de_finalisation'
                          ? null
                          : () => _envoyerInteret(comp),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kOrange,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Intéressé',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Mini-carte avec itineraire
            if (hasGps) ...[
              const SizedBox(height: 10),
              Container(
                height: 130,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                child: _carteItineraireCompat(
                  theirDepLat: theirDepLat,
                  theirDepLng: theirDepLng,
                  theirArrLat: theirArrLat,
                  theirArrLng: theirArrLng,
                  monDepLat: (comp['monDepartLat'] as num?)?.toDouble(),
                  monDepLng: (comp['monDepartLng'] as num?)?.toDouble(),
                  monArrLat: (comp['monArriveeLat'] as num?)?.toDouble(),
                  monArrLng: (comp['monArriveeLng'] as num?)?.toDouble(),
                  isDetour: isDetour,
                ),
              ),
              // Distance approximative (confidentialite)
              const SizedBox(height: 6),
              _distanceInfoRow(comp),
            ],
          ],
        ),
      ),
    );
  }

  Widget _carteItineraireCompat({
    required double theirDepLat,
    required double theirDepLng,
    required double theirArrLat,
    required double theirArrLng,
    required double? monDepLat,
    required double? monDepLng,
    required double? monArrLat,
    required double? monArrLng,
    required bool isDetour,
  }) {
    final theirDep = LatLng(theirDepLat, theirDepLng);
    final theirArr = LatLng(theirArrLat, theirArrLng);

    // Center de la carte
    final allPoints = <LatLng>[theirDep, theirArr];
    if (monDepLat != null && monDepLng != null) allPoints.add(LatLng(monDepLat, monDepLng));
    if (monArrLat != null && monArrLng != null) allPoints.add(LatLng(monArrLat, monArrLng));

    final bounds = LatLngBounds.fromPoints(allPoints);
    final center = bounds.center;

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 12,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'ml.sirakele.sirakele',
        ),
        MarkerLayer(
          markers: [
            Marker(point: theirDep, width: 20, height: 20, child: const Icon(Icons.circle, color: kGreen, size: 12)),
            Marker(point: theirArr, width: 20, height: 20, child: const Icon(Icons.circle, color: Color(0xFF2962FF), size: 12)),
            if (monDepLat != null && monDepLng != null)
              Marker(
                point: LatLng(monDepLat, monDepLng),
                width: 16,
                height: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: kOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _distanceInfoRow(Map<String, dynamic> comp) {
    final theirDepLat = (comp['departLat'] as num?)?.toDouble();
    final theirDepLng = (comp['departLng'] as num?)?.toDouble();
    final monDepLat = (comp['monDepartLat'] as num?)?.toDouble();
    final monDepLng = (comp['monDepartLng'] as num?)?.toDouble();

    String proximite = '';
    if (theirDepLat != null && monDepLat != null) {
      final distKm = const Distance().as(
        LengthUnit.Kilometer,
        LatLng(theirDepLat, theirDepLng!),
        LatLng(monDepLat, monDepLng!),
      );
      proximite = CarteService.distanceApproximative(distKm);
    }

    return Row(
      children: [
        Icon(Icons.near_me_rounded, size: 14, color: kOrange),
        const SizedBox(width: 4),
        Text(
          proximite.isNotEmpty ? 'Depart a proximite ($proximite)' : 'Meme itineraire',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kOrange),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kOrangeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.route_rounded, color: kOrange, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun trajet publié',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Publiez votre premier Avis de Déplacement pour découvrir des trajets compatibles près de chez vous.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kTextSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _chargerMonAd,
          color: kOrange,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.prenom.isEmpty ? 'Bienvenue' : widget.prenom,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.notifications_none_rounded, color: kOrange),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_chargement)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: kOrange)),
                )
              else if (_adActif != null) ...[
                // Active AD card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF8F0), Color(0xFFFFF3E6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kOrange.withAlpha(60), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'MON AD ACTIF',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: kTextSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _adActif!['statut'] == 'actif'
                                  ? kGreenLight
                                  : const Color(0xFFFFE8D4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _libelleStatut(_adActif!['statut'] as String),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _adActif!['statut'] == 'actif'
                                    ? kGreen
                                    : const Color(0xFFB35A00),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: kOrange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.route_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${_adActif!['depart']} → ${_adActif!['destination']}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_adActif!['dateDeplacement']} à ${_adActif!['heureDepart']}'
                        '${_adActif!['role'] == 'conducteur' ? ' · ${_adActif!['moyenTransport']} · ${_adActif!['placesDisponibles']} place(s)' : ''}',
                        style: TextStyle(fontSize: 12, color: kTextSecondary),
                      ),
                      if (_partenaire != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kGreenLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: kGreen, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProfilAutreScreen(
                                            targetUserId: _partenaire!['id'] as String,
                                            viewerUserId: widget.userId,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Partenaire : ${_partenaire!['prenom']} ${_partenaire!['nom']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF125A1E),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await WhatsAppHelper.ouvrir(
                                      telephone: '${_partenaire!['telephone']}',
                                      message: 'Bonjour ${_partenaire!['prenom']}, je te contacte au sujet du trajet SIRA KELEN.',
                                    );
                                  },
                                  icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 16),
                                  label: const Text(
                                    'Contacter via WhatsApp',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _annulerAd,
                          child: const Text(
                            'Annuler cet AD',
                            style: TextStyle(
                              fontSize: 12,
                              color: kRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (_adActif!['statut'] == 'en_cours_de_finalisation') ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: FilledButton.icon(
                            onPressed: () async {
                              try {
                                await ApiService.marquerOrganise(
                                    _adActif!['id'] as String, widget.userId);
                                await _chargerMonAd();
                              } catch (_) {}
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Marquer comme trajet organisé'),
                            style: FilledButton.styleFrom(
                              backgroundColor: kGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Requests received
                if (_demandesRecues.isNotEmpty) ...[
                  _sectionTitle('${_demandesRecues.length} demande${_demandesRecues.length > 1 ? 's' : ''} reçue${_demandesRecues.length > 1 ? 's' : ''}'),
                  ..._demandesRecues.map(
                      (d) => _carteDemandeRecue(d as Map<String, dynamic>)),
                  const SizedBox(height: 8),
                ],

                // Requests sent
                if (_demandesEnvoyees.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _sectionTitle('MES DEMANDES ENVOYÉES'),
                  ..._demandesEnvoyees.map(
                      (d) => _carteDemandeEnvoyee(d as Map<String, dynamic>)),
                ],

                // Compatibilities
                if (_compatibilites.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _sectionTitle('${_compatibilites.length} compatibilité${_compatibilites.length > 1 ? 's' : ''} trouvée${_compatibilites.length > 1 ? 's' : ''}'),
                  ..._compatibilites.map(
                      (c) => _carteCompatibilite(c as Map<String, dynamic>)),
                ] else
                  _emptyState(),

                const SizedBox(height: 10),
                Center(
                  child: Text(
                    _adActif!['role'] == 'conducteur'
                        ? 'Recherche de passagers compatibles…'
                        : 'Recherche de conducteurs compatibles…',
                    style: TextStyle(
                      fontSize: 13,
                      color: kTextSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ] else ...[
                _emptyState(),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
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
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text('Publier un AD'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
