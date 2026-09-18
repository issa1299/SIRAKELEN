import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

/// Service de cartographie SIRA KELEN.
/// Geocodage, recherche de lieux, distance, preview d'itineraire.
class CarteService {
  static const _nominatimUrl = 'https://nominatim.openstreetmap.org';
  static const _osrmUrl = 'https://router.project-osrm.org';
  static const _headers = {'User-Agent': 'SiraKelen/1.0 (sirakele@app.com)'};

  // --- Geocodage inverse : coordonnees → nom de lieu ---
  static Future<String> geocoderInverse(double lat, double lng) async {
    try {
      final url = Uri.parse(
        '$_nominatimUrl/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1',
      );
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final parts = <String>[];
        if (addr['road'] != null) parts.add(addr['road']);
        if (addr['neighbourhood'] != null) parts.add(addr['neighbourhood']);
        if (addr['suburb'] != null) parts.add(addr['suburb']);
        if (addr['quarter'] != null) parts.add(addr['quarter']);
        if (addr['city'] != null) parts.add(addr['city']);
        if (parts.isNotEmpty) return parts.join(', ');
        return data['display_name'] ?? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }
    } catch (_) {}
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  // --- Recherche de lieux ---
  static Future<List<LieuResultat>> rechercher(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final url = Uri.parse(
        '$_nominatimUrl/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=6&addressdetails=1&countrycodes=ml',
      );
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((r) => LieuResultat.fromNominatim(r)).toList();
      }
    } catch (_) {}
    return [];
  }

  // --- Itineraire OSRM : distance, duree, GEOMETRIE reelle ---
  static Future<ItineraireInfo?> calculerItineraire(
      LatLng depart, LatLng arrivee) async {
    try {
      final url = Uri.parse(
        '$_osrmUrl/route/v1/driving/'
        '${depart.longitude},${depart.latitude};'
        '${arrivee.longitude},${arrivee.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes[0] as Map<String, dynamic>;
          final distMeters = (route['distance'] as num).toDouble();
          final durSec = (route['duration'] as num).toDouble();

          // Extraire la geometrie reelle (GeoJSON coordinates)
          final geometry = route['geometry'] as Map<String, dynamic>?;
          final coords = <LatLng>[];
          if (geometry != null && geometry['coordinates'] != null) {
            for (final c in (geometry['coordinates'] as List)) {
              coords.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
            }
          }

          return ItineraireInfo(
            distanceKm: distMeters / 1000,
            dureeMinutes: (durSec / 60).ceil(),
            points: coords.isNotEmpty ? coords : [depart, arrivee],
          );
        }
      }
    } catch (_) {}
    // Fallback : ligne droite
    final distKm = Distance().as(LengthUnit.Kilometer, depart, arrivee);
    final dureeMin = (distKm / 30 * 60).ceil();
    return ItineraireInfo(
      distanceKm: distKm,
      dureeMinutes: dureeMin,
      points: [depart, arrivee],
    );
  }

  // --- Itineraire avec deplacement (conducteur → point intermediaire → arrivee) ---
  static Future<ItineraireAvecDetour?> calculerItineraireDetour(
      LatLng departConducteur, LatLng pointIntermediaire, LatLng arrivee) async {
    try {
      final url = Uri.parse(
        '$_osrmUrl/route/v1/driving/'
        '${departConducteur.longitude},${departConducteur.latitude};'
        '${pointIntermediaire.longitude},${pointIntermediaire.latitude};'
        '${arrivee.longitude},${arrivee.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes[0] as Map<String, dynamic>;
          final distMeters = (route['distance'] as num).toDouble();
          final durSec = (route['duration'] as num).toDouble();

          // Geometrie reelle
          final geometry = route['geometry'] as Map<String, dynamic>?;
          final coords = <LatLng>[];
          if (geometry != null && geometry['coordinates'] != null) {
            for (final c in (geometry['coordinates'] as List)) {
              coords.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
            }
          }

          // Itineraire direct (sans detour) pour comparaison
          final direct = await calculerItineraire(departConducteur, arrivee);

          final dureeDetour = (durSec / 60).ceil();
          final dureeDirect = direct?.dureeMinutes ?? dureeDetour;
          final detourMinutes = dureeDetour - dureeDirect;

          return ItineraireAvecDetour(
            distanceKm: distMeters / 1000,
            dureeMinutes: dureeDetour,
            points: coords.isNotEmpty ? coords : [departConducteur, pointIntermediaire, arrivee],
            detourMinutes: detourMinutes > 0 ? detourMinutes : 0,
          );
        }
      }
    } catch (_) {}
    // Fallback
    final direct = await calculerItineraire(departConducteur, arrivee);
    return ItineraireAvecDetour(
      distanceKm: direct?.distanceKm ?? 0,
      dureeMinutes: direct?.dureeMinutes ?? 0,
      points: [departConducteur, pointIntermediaire, arrivee],
      detourMinutes: 0,
    );
  }

  // --- Formatter distance pour affichage ---
  static String formaterDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  // --- Formatter duree pour affichage ---
  static String formaterDuree(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h${m.toString().padLeft(2, '0')}' : '${h}h';
  }

  // --- Distance approximative pour le matching (confidentialite) ---
  static String distanceApproximative(double km) {
    if (km < 0.1) return 'tres pres';
    if (km < 0.3) return '~300 m';
    if (km < 0.5) return '~500 m';
    if (km < 1) return '~${(km * 1000 / 100).round() * 100} m';
    return '~${km.toStringAsFixed(0)} km';
  }
}

class LieuResultat {
  final String nom;
  final String adresseComplete;
  final LatLng position;

  LieuResultat({
    required this.nom,
    required this.adresseComplete,
    required this.position,
  });

  factory LieuResultat.fromNominatim(Map<String, dynamic> r) {
    final lat = double.tryParse(r['lat'] ?? '') ?? 0;
    final lon = double.tryParse(r['lon'] ?? '') ?? 0;
    final addr = r['address'] as Map<String, dynamic>? ?? {};
    final parts = <String>[];
    if (addr['road'] != null) parts.add(addr['road']);
    if (addr['neighbourhood'] != null) parts.add(addr['neighbourhood']);
    if (addr['suburb'] != null) parts.add(addr['suburb']);
    if (addr['quarter'] != null) parts.add(addr['quarter']);
    if (addr['city'] != null) parts.add(addr['city']);
    return LieuResultat(
      nom: parts.isNotEmpty ? parts.join(', ') : (r['display_name'] ?? ''),
      adresseComplete: r['display_name'] ?? '',
      position: LatLng(lat, lon),
    );
  }
}

class ItineraireInfo {
  final double distanceKm;
  final int dureeMinutes;
  final List<LatLng> points;

  ItineraireInfo({
    required this.distanceKm,
    required this.dureeMinutes,
    this.points = const [],
  });
}

class ItineraireAvecDetour {
  final double distanceKm;
  final int dureeMinutes;
  final List<LatLng> points;
  final int detourMinutes;

  ItineraireAvecDetour({
    required this.distanceKm,
    required this.dureeMinutes,
    required this.points,
    required this.detourMinutes,
  });
}
