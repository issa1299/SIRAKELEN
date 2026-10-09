import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/carte_service.dart';

class PublierScreen extends StatefulWidget {
  final String userId;
  const PublierScreen({super.key, required this.userId});

  @override
  State<PublierScreen> createState() => _PublierScreenState();
}

class _PublierScreenState extends State<PublierScreen> {
  String? _role;
  final _heure = TextEditingController();
  final _places = TextEditingController(text: '1');
  String _date = '';
  bool _chargement = false;
  String? _erreur;
  bool _publie = false;
  bool _apercu = false;

  static const List<String> _transports = ['Voiture', 'Moto'];
  String? _transportChoisi = 'Voiture';

  // --- Carte ---
  final MapController _mapController = MapController();
  int _etape = 0; // 0=depart, 1=destination, 2=apercu
  LatLng? _departPoint;
  LatLng? _arriveePoint;
  String _departNom = '';
  String _arriveeNom = '';
  List<LieuResultat> _rechercheResultats = [];
  bool _rechercheEnCours = false;
  final _rechercheController = TextEditingController();
  ItineraireInfo? _itineraire;
  // Epingle centrale : le point suit le centre de la carte.
  LatLng? _centreTemp;
  bool _nomEnCours = false;
  Timer? _debounceGeo;

  static const LatLng _bamakoCenter = LatLng(12.6392, -8.0029);

  @override
  void initState() {
    super.initState();
    final demain = DateTime.now().add(const Duration(days: 1));
    _date = _formatDate(demain);
    _heure.text = '07:30';
  }

  @override
  void dispose() {
    _heure.dispose();
    _places.dispose();
    _rechercheController.dispose();
    _debounceGeo?.cancel();
    super.dispose();
  }

  /// Appelé quand l'utilisateur bouge la carte : le point suit le centre.
  void _centreChange(LatLng centre) {
    _centreTemp = centre;
    _debounceGeo?.cancel();
    _debounceGeo = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _nomEnCours = true;
        if (_etape == 0) {
          _departPoint = centre;
          _departNom = '';
        } else {
          _arriveePoint = centre;
          _arriveeNom = '';
        }
      });
      CarteService.geocoderInverse(centre.latitude, centre.longitude).then((nom) {
        if (!mounted) return;
        setState(() {
          _nomEnCours = false;
          if (_etape == 0) {
            if (_departPoint == centre) _departNom = nom;
          } else {
            if (_arriveePoint == centre) _arriveeNom = nom;
          }
        });
      });
      if (_etape == 1) _mettreAJourItineraire();
    });
  }

  /// Centre de la carte = choix actuel (jamais vide).
  LatLng _choixActuel() {
    if (_etape == 0) return _centreTemp ?? _departPoint ?? _bamakoCenter;
    return _centreTemp ?? _arriveePoint ?? _departPoint ?? _bamakoCenter;
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // === RECHERCHE ===
  Future<void> _rechercher(String query) async {
    if (query.trim().length < 2) {
      setState(() => _rechercheResultats = []);
      return;
    }
    setState(() => _rechercheEnCours = true);
    final resultats = await CarteService.rechercher(query);
    if (mounted) {
      setState(() {
        _rechercheResultats = resultats;
        _rechercheEnCours = false;
      });
    }
  }

  void _selectionnerLieu(LieuResultat lieu) {
    setState(() {
      _rechercheResultats = [];
      _rechercheController.clear();
    });
    if (_etape == 0) {
      _departPoint = lieu.position;
      _departNom = lieu.nom;
    } else {
      _arriveePoint = lieu.position;
      _arriveeNom = lieu.nom;
    }
    _centreTemp = lieu.position;
    _debounceGeo?.cancel();
    _mapController.move(lieu.position, 16);
    _mettreAJourItineraire();
  }

  void _confirmerPoint() {
    // Fige le centre actuel de la carte comme choix.
    final choix = _choixActuel();
    if (_etape == 0) {
      setState(() {
        _departPoint = choix;
        _centreTemp = choix;
        if (_departNom.isEmpty) _departNom = 'Point sur la carte';
        _etape = 1;
      });
      _rechercheController.clear();
      _rechercheResultats = [];
      // Recentre la vue sur le départ pour l'étape destination.
      _mapController.move(choix, 14);
      _centreTemp = choix;
    } else {
      setState(() {
        _arriveePoint = choix;
        _centreTemp = choix;
        if (_arriveeNom.isEmpty) _arriveeNom = 'Point sur la carte';
      });
      _calculerApercu();
    }
  }

  void _retour() {
    if (_etape > 0) {
      setState(() {
        _etape--;
        if (_etape == 0) {
          _arriveePoint = null;
          _arriveeNom = '';
          _itineraire = null;
        }
        _rechercheController.clear();
        _rechercheResultats = [];
      });
    }
  }

  Future<void> _utiliserMaPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final point = LatLng(pos.latitude, pos.longitude);
      final nom = await CarteService.geocoderInverse(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _centreTemp = point;
        if (_etape == 0) {
          _departPoint = point;
          _departNom = nom;
        } else {
          _arriveePoint = point;
          _arriveeNom = nom;
        }
      });
      _mapController.move(point, 16);
      _mettreAJourItineraire();
    } catch (_) {}
  }

  void _mettreAJourItineraire() {
    if (_departPoint != null && _arriveePoint != null) {
      CarteService.calculerItineraire(_departPoint!, _arriveePoint!).then((info) {
        if (mounted) setState(() => _itineraire = info);
      });
    }
  }

  Future<void> _calculerApercu() async {
    _mettreAJourItineraire();
    // Attendre un peu pour que l'itineraire soit charge
    if (_departPoint != null && _arriveePoint != null) {
      final info = await CarteService.calculerItineraire(_departPoint!, _arriveePoint!);
      if (mounted) setState(() {
        _itineraire = info;
        _apercu = true;
      });
    } else {
      setState(() => _apercu = true);
    }
  }

  // === PUBLICATION ===
  Future<void> _publier() async {
    if (_departPoint == null || _arriveePoint == null || _heure.text.isEmpty) {
      setState(() => _erreur = 'Remplis tous les champs');
      return;
    }
    if (_role == 'conducteur' && _places.text.isEmpty) {
      setState(() => _erreur = 'Indique le nombre de places');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await ApiService.publierAd(
        userId: widget.userId,
        role: _role!,
        depart: _departNom,
        destination: _arriveeNom,
        dateDeplacement: _date,
        heureDepart: _heure.text,
        moyenTransport: _role == 'conducteur' ? (_transportChoisi ?? 'Voiture') : null,
        placesDisponibles: _role == 'conducteur' ? int.tryParse(_places.text) : null,
        departLat: _departPoint!.latitude,
        departLng: _departPoint!.longitude,
        arriveeLat: _arriveePoint!.latitude,
        arriveeLng: _arriveePoint!.longitude,
      );
      if (!mounted) return;
      setState(() {
        _publie = true;
        _chargement = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    } catch (_) {
      setState(() {
        _erreur = 'Connexion au serveur impossible';
        _chargement = false;
      });
    }
  }

  Future<void> _choisirDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kOrange),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = _formatDate(picked));
  }

  Future<void> _choisirHeure() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 30),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kOrange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _heure.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  // === BUILD ===
  @override
  Widget build(BuildContext context) {
    if (_publie) return _ecranSucces();
    if (_apercu) return _ecranApercu();
    if (_role == null) return _ecranRoleSelection();
    return _ecranCarte();
  }

  // --- Ecran selection du role ---
  Widget _ecranRoleSelection() {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Publier un AD')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text('Quel est ton statut ?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary)),
            const SizedBox(height: 14),
            _carteRole(
              icone: Icons.directions_car_rounded,
              titre: 'Je conduis',
              description: 'Je propose des places dans mon vehicule.',
              valeur: 'conducteur',
            ),
            const SizedBox(height: 10),
            _carteRole(
              icone: Icons.person_search_rounded,
              titre: 'Je cherche un trajet',
              description: 'Je veux rejoindre un conducteur compatible.',
              valeur: 'passager',
            ),
          ],
        ),
      ),
    );
  }

  // --- Ecran carte (2 etapes) ---
  Widget _ecranCarte() {
    final bool isDepart = _etape == 0;
    final String nomActuel = isDepart ? _departNom : _arriveeNom;

    return Scaffold(
      body: Stack(
        children: [
          // Carte : l'utilisateur BOUGE la carte sous l'épingle fixe.
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _departPoint ?? _bamakoCenter,
              initialZoom: 13,
              onPositionChanged: (pos, aBouge) {
                if (aBouge && pos.center != null) _centreChange(pos.center!);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ml.sirakele.sirakele',
              ),
              // Ligne reelle OSREM
              if (_departPoint != null && _arriveePoint != null && _itineraire != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _itineraire!.points,
                      color: kOrange.withAlpha(180),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              // Ligne droite fallback si pas encore charge
              if (_departPoint != null && _arriveePoint != null && _itineraire == null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_departPoint!, _arriveePoint!],
                      color: kOrange.withAlpha(80),
                      strokeWidth: 2,
                    ),
                  ],
                ),
              // Départ déjà fixé (étape destination) + ligne réelle.
              MarkerLayer(
                markers: [
                  if (!isDepart && _departPoint != null)
                    Marker(
                      point: _departPoint!,
                      width: 40,
                      height: 40,
                      child: _pin('D', kGreen),
                    ),
                ],
              ),
            ],
          ),

          // Épingle FIXE au centre : c'est elle qu'on place en bougeant la carte.
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _pin(isDepart ? 'D' : 'A', isDepart ? kGreen : const Color(0xFF2962FF)),
                    Container(
                      width: 14,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(50),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Header carte blanche
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 12, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _etape == 0 ? () => setState(() { _role = null; }) : _retour,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: kCream, shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back_rounded, color: kTextPrimary, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDepart ? 'Où partez-vous ?' : 'Où allez-vous ?',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: kTextPrimary,
                              ),
                            ),
                            Text(
                              isDepart
                                  ? 'Étape 1 sur 2 · Touchez la carte ou cherchez'
                                  : 'Étape 2 sur 2 · Choisissez l\'arrivée',
                              style: TextStyle(fontSize: 12, color: kTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (_etape + 1) / 2,
                      minHeight: 6,
                      backgroundColor: kOrangeLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(kOrange),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barre de recherche
          Positioned(
            top: MediaQuery.of(context).padding.top + 168,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: TextField(
                    controller: _rechercheController,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: isDepart ? 'Rechercher un lieu de depart...' : 'Rechercher une destination...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search_rounded, color: kOrange),
                      suffixIcon: _rechercheController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                _rechercheController.clear();
                                setState(() => _rechercheResultats = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: _rechercher,
                  ),
                ),
                if (_rechercheEnCours || _rechercheResultats.isNotEmpty || _rechercheController.text.trim().length >= 2)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8)],
                    ),
                    child: _rechercheEnCours
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                          )
                        : _rechercheResultats.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.search_off_rounded, color: kTextSecondary, size: 20),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Aucun lieu trouvé. Touchez la carte pour placer le point.',
                                        style: TextStyle(fontSize: 13, color: kTextSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _rechercheResultats.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withAlpha(20)),
                            itemBuilder: (ctx, i) {
                              final r = _rechercheResultats[i];
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.location_on_outlined, color: kOrange, size: 20),
                                title: Text(r.nom, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(r.adresseComplete, style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                                onTap: () => _selectionnerLieu(r),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),

          // Barre du bas : guide l'utilisateur étape par étape.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: kBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Lieu sous l'épingle
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kCream,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDepart ? kGreen : const Color(0xFF2962FF),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                isDepart ? 'D' : 'A',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDepart ? 'DÉPART · bouge la carte' : 'DESTINATION · bouge la carte',
                                  style: TextStyle(fontSize: 11, color: kTextSecondary, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                _nomEnCours || nomActuel.isEmpty
                                    ? Row(
                                        children: [
                                          SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: kOrange),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('Recherche du lieu…',
                                              style: TextStyle(fontSize: 14, color: kTextSecondary)),
                                        ],
                                      )
                                    : Text(nomActuel,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Récap départ fixé à l'étape 2
                    if (!isDepart && _departPoint != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _retour,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: kGreen.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: kGreen, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Départ : $_departNom',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text('Modifier',
                                  style: TextStyle(fontSize: 12, color: kOrange, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_itineraire != null && _departPoint != null && _arriveePoint != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: kOrangeLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.route_rounded, color: kOrange, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${CarteService.formaterDistance(_itineraire!.distanceKm)} · ${CarteService.formaterDuree(_itineraire!.dureeMinutes)}',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kOrange),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _utiliserMaPosition,
                              icon: Icon(Icons.my_location_rounded, color: kOrange, size: 20),
                              label: Text('Ma position',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kOrange)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: kOrange.withAlpha(120)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _confirmerPoint,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(isDepart ? 'Confirmer le départ' : 'Voir l\'aperçu'),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pin D / A avec bordure blanche.
  Widget _pin(String lettre, Color couleur) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: couleur,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Center(
        child: Text(
          lettre,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }

  // --- Ecran apercu (avec champs heure/date/places) ---
  Widget _ecranApercu() {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        title: const Text('Apercu du trajet'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => setState(() => _apercu = false)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // Mini-carte avec itineraire reelle
            Container(
              height: 200,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _departPoint!,
                  initialZoom: 12,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all - InteractiveFlag.rotate),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'ml.sirakele.sirakele',
                  ),
                  // Ligne reelle sur les routes
                  if (_itineraire != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _itineraire!.points,
                          color: kOrange,
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  if (_itineraire == null && _departPoint != null && _arriveePoint != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(points: [_departPoint!, _arriveePoint!], color: kOrange, strokeWidth: 3),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(point: _departPoint!, width: 30, height: 30, child: const Icon(Icons.circle, color: kGreen, size: 16)),
                      Marker(point: _arriveePoint!, width: 30, height: 30, child: const Icon(Icons.circle, color: Color(0xFF2962FF), size: 16)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Resume trajet
            _recapLigne(Icons.circle, kGreen, 'Depart', _departNom),
            _recapLigne(Icons.circle, const Color(0xFF2962FF), 'Destination', _arriveeNom),
            const SizedBox(height: 16),

            // --- Champs a remplir ---
            _sectionLabel('Heure de depart'),
            GestureDetector(
              onTap: _choisirHeure,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: kOrange, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _heure.text.isNotEmpty ? _heure.text : 'Choisir l\'heure',
                      style: TextStyle(
                        fontSize: 15,
                        color: _heure.text.isNotEmpty ? kTextPrimary : kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _sectionLabel('Date'),
            GestureDetector(
              onTap: _choisirDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: kOrange, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _dateLisible(),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_role == 'conducteur') ...[
              _sectionLabel('Nombre de places'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_seat_rounded, color: kOrange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _places,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Ex: 2',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _sectionLabel('Moyen de transport'),
              Row(
                children: _transports.map((t) {
                  final selected = _transportChoisi == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _transportChoisi = t),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? kOrange : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selected ? kOrange : kBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              t == 'Voiture' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                              color: selected ? Colors.white : kTextSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Distance / duree
            if (_itineraire != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kOrangeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.route_rounded, color: kOrange, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      '${CarteService.formaterDistance(_itineraire!.distanceKm)}  ·  ${CarteService.formaterDuree(_itineraire!.dureeMinutes)}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kOrange),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            if (_erreur != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: kRedLight, borderRadius: BorderRadius.circular(12)),
                child: Text(_erreur!, style: const TextStyle(color: kRed, fontSize: 13)),
              ),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _chargement ? null : _publier,
                child: _chargement
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Text(_role == 'conducteur' ? 'Publier mon AD' : 'Rechercher les trajets compatibles'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextSecondary),
      ),
    );
  }

  Widget _recapLigne(IconData icone, Color couleur, String label, String valeur) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
      child: Row(
        children: [
          Icon(icone, color: couleur, size: 12),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, color: kTextSecondary)),
          const Spacer(),
          Flexible(
            child: Text(valeur, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _dateLisible() {
    final d = DateTime.tryParse(_date);
    if (d == null) return _date;
    const mois = ['janvier','fevrier','mars','avril','mai','juin','juillet','aout','septembre','octobre','novembre','decembre'];
    return '${d.day} ${mois[d.month - 1]}';
  }

  // --- Ecran succes ---
  Widget _ecranSucces() {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('AD publie')),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 24),
            Text(
              _role == 'conducteur' ? 'Ton AD conducteur est publie !' : 'Ton AD passager est publie !',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              _role == 'conducteur'
                  ? 'Les passagers compatibles verront ton trajet.'
                  : 'Nous cherchons les conducteurs compatibles.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kTextSecondary),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour a l\'accueil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carteRole({
    required IconData icone,
    required String titre,
    required String description,
    required String valeur,
  }) {
    final selected = _role == valeur;
    return GestureDetector(
      onTap: () => setState(() => _role = valeur),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? kOrangeLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? kOrange : kBorder, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? kOrange : kGreyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: selected ? Colors.white : kTextSecondary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(description, style: TextStyle(fontSize: 12, color: kTextSecondary, height: 1.4)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: kOrange, size: 22),
          ],
        ),
      ),
    );
  }
}
