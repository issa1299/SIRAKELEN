import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart';
import '../services/carte_service.dart';

/// Mini-carte d'un AD : itineraire reel OSRM + distance/duree.
/// Reutilisee par l'accueil (AD actif) et par le detail d'un AD parcouru.
class MiniTrajetMap extends StatefulWidget {
  final Map<String, dynamic> ad;
  final double height;
  const MiniTrajetMap({super.key, required this.ad, this.height = 140});

  @override
  State<MiniTrajetMap> createState() => _MiniTrajetMapState();
}

class _MiniTrajetMapState extends State<MiniTrajetMap> {
  ItineraireInfo? _iti;

  @override
  void initState() {
    super.initState();
    final depLat = (widget.ad['departLat'] as num?)?.toDouble();
    final depLng = (widget.ad['departLng'] as num?)?.toDouble();
    final arrLat = (widget.ad['arriveeLat'] as num?)?.toDouble();
    final arrLng = (widget.ad['arriveeLng'] as num?)?.toDouble();
    if (depLat != null && depLng != null && arrLat != null && arrLng != null) {
      CarteService.calculerItineraire(LatLng(depLat, depLng), LatLng(arrLat, arrLng)).then((iti) {
        if (mounted) setState(() => _iti = iti);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final depLat = (widget.ad['departLat'] as num?)?.toDouble();
    final depLng = (widget.ad['departLng'] as num?)?.toDouble();
    final arrLat = (widget.ad['arriveeLat'] as num?)?.toDouble();
    final arrLng = (widget.ad['arriveeLng'] as num?)?.toDouble();
    if (depLat == null || depLng == null || arrLat == null || arrLng == null) {
      return const SizedBox.shrink();
    }
    final dep = LatLng(depLat, depLng);
    final arr = LatLng(arrLat, arrLng);
    final points = _iti?.points ?? [dep, arr];

    return Column(
      children: [
        Container(
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng((depLat + arrLat) / 2, (depLng + arrLng) / 2),
              initialZoom: 12,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ml.sirakele.sirakele',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(points: points, color: kOrange, strokeWidth: 3.5),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(point: dep, width: 22, height: 22, child: const Icon(Icons.circle, color: kGreen, size: 13)),
                  Marker(point: arr, width: 22, height: 22, child: const Icon(Icons.circle, color: Color(0xFF2962FF), size: 13)),
                ],
              ),
            ],
          ),
        ),
        if (_iti != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.route_rounded, size: 15, color: kOrange),
              const SizedBox(width: 6),
              Text(
                '${CarteService.formaterDistance(_iti!.distanceKm)} · ${CarteService.formaterDuree(_iti!.dureeMinutes)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kOrange),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
