import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final String title;

  const MapPickerScreen({
    super.key,
    this.initialPosition,
    this.title = 'Choisir un point',
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late final MapController _mapController;
  LatLng? _selectedPoint;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _showResults = false;

  static const LatLng _bamakoCenter = LatLng(12.6392, -8.0029);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedPoint = widget.initialPosition;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _rechercher(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _showResults = true;
    });
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&limit=6'
        '&addressdetails=1'
        '&countrycodes=ml',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'SiraKelen/1.0 (sirakele@app.com)',
      });
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _results = data.cast<Map<String, dynamic>>();
          _searching = false;
        });
      } else {
        setState(() {
          _results = [];
          _searching = false;
        });
      }
    } catch (_) {
      setState(() {
        _results = [];
        _searching = false;
      });
    }
  }

  void _selectionnerResultat(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat'] ?? '');
    final lon = double.tryParse(result['lon'] ?? '');
    if (lat == null || lon == null) return;
    final point = LatLng(lat, lon);
    setState(() {
      _selectedPoint = point;
      _showResults = false;
      _searchFocus.unfocus();
    });
    _mapController.move(point, 16);
  }

  String _formatDisplayName(Map<String, dynamic> result) {
    final addr = result['address'] as Map<String, dynamic>? ?? {};
    final parts = <String>[];
    if (addr['road'] != null) parts.add(addr['road']);
    if (addr['neighbourhood'] != null) parts.add(addr['neighbourhood']);
    if (addr['suburb'] != null) parts.add(addr['suburb']);
    if (addr['quarter'] != null) parts.add(addr['quarter']);
    if (addr['city'] != null) parts.add(addr['city']);
    if (addr['state'] != null) parts.add(addr['state']);
    if (parts.isEmpty) {
      return result['display_name'] ?? '';
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_selectedPoint != null)
            TextButton.icon(
              onPressed: () => Navigator.pop(context, _selectedPoint),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Valider',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Carte
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint ?? _bamakoCenter,
              initialZoom: 13,
              onTap: (tapPosition, latLng) {
                setState(() {
                  _selectedPoint = latLng;
                  _showResults = false;
                });
                _searchFocus.unfocus();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'ml.sirakele.sirakele',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_pin,
                        color: kOrange,
                        size: 44,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Barre de recherche
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un lieu...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search_rounded, color: kOrange),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _results = [];
                                  _showResults = false;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: _rechercher,
                    onSubmitted: (v) => _rechercher(v),
                  ),
                ),

                // Resultats
                if (_showResults) ...[
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          )
                        : _results.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Aucun resultat pour "${_searchController.text}"',
                                  style: TextStyle(
                                    color: kTextSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _results.length,
                                separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey.withAlpha(30)),
                                itemBuilder: (context, index) {
                                  final r = _results[index];
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(Icons.location_on_outlined,
                                        color: kOrange, size: 20),
                                    title: Text(
                                      _formatDisplayName(r),
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      r['display_name'] ?? '',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _selectionnerResultat(r),
                                  );
                                },
                              ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedPoint == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_selectedPoint!.latitude.toStringAsFixed(5)}, ${_selectedPoint!.longitude.toStringAsFixed(5)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: kTextSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, _selectedPoint),
                        child: const Text('Confirmer ce point'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
