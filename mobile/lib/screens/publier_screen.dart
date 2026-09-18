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
    super.dispose();
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
    _mapController.move(lieu.position, 16);
    _mettreAJourItineraire();
  }

  void _confirmerPoint() {
    if (_etape == 0 && _departPoint != null) {
      setState(() => _etape = 1);
      _rechercheController.clear();
      _rechercheResultats = [];
    } else if (_etape == 1 && _arriveePoint != null) {
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
      setState(() {
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
    final LatLng? pointActuel = isDepart ? _departPoint : _arriveePoint;
    final String nomActuel = isDepart ? _departNom : _arriveeNom;

    return Scaffold(
      body: Stack(
        children: [
          // Carte
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _departPoint ?? _bamakoCenter,
              initialZoom: 13,
              onTap: (_, latLng) {
                setState(() {
                  if (isDepart) {
                    _departPoint = latLng;
                    _departNom = '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
                  } else {
                    _arriveePoint = latLng;
                    _arriveeNom = '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
                  }
                });
                CarteService.geocoderInverse(latLng.latitude, latLng.longitude).then((nom) {
                  if (mounted) setState(() {
                    if (isDepart) _departNom = nom;
                    else _arriveeNom = nom;
                  });
                });
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
              // Marqueurs
              MarkerLayer(
                markers: [
                  if (_departPoint != null)
                    Marker(
                      point: _departPoint!,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.circle, color: kGreen, size: 18),
                    ),
                  if (_arriveePoint != null)
                    Marker(
                      point: _arriveePoint!,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.circle, color: Color(0xFF2962FF), size: 18),
                    ),
                ],
              ),
            ],
          ),

          // AppBar transparente
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withAlpha(80), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: _etape == 0 ? () => setState(() { _role = null; }) : _retour,
                  ),
                  Expanded(
                    child: Text(
                      isDepart ? 'Ou partez-vous ?' : 'Ou allez-vous ?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(200),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _stepDot(0, '1'),
                        Container(width: 16, height: 1, color: Colors.grey[300]),
                        _stepDot(1, '2'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barre de recherche
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
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
                if (_rechercheResultats.isNotEmpty || _rechercheEnCours)
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

          // Bouton Ma position
          Positioned(
            bottom: 120,
            right: 12,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _utiliserMaPosition,
              child: Icon(Icons.my_location_rounded, color: kOrange, size: 22),
            ),
          ),

          // Barre du bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pointActuel != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kOrangeLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, color: isDepart ? kGreen : const Color(0xFF2962FF), size: 12),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isDepart ? 'Depart' : 'Destination',
                                      style: TextStyle(fontSize: 11, color: kTextSecondary, fontWeight: FontWeight.w600)),
                                  Text(nomActuel.isNotEmpty ? nomActuel : 'Point sur la carte',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            Icon(Icons.check_circle_rounded, color: kOrange, size: 22),
                          ],
                        ),
                      )
                    else
                      Text(
                        isDepart ? 'Tape sur la carte ou recherche un lieu' : 'Tape sur la carte ou recherche une destination',
                        style: TextStyle(color: kTextSecondary, fontSize: 13),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: pointActuel == null ? null : _confirmerPoint,
                        child: Text(isDepart ? 'Confirmer le depart' : 'Voir l\'apercu'),
                      ),
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

  Widget _stepDot(int step, String label) {
    final active = _etape >= step;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? kOrange : Colors.grey[300],
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? Colors.white : kTextSecondary)),
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
