/// Service centralisé de vérification des mises à jour (Android + Web).
/// Ne dépend d'aucun plugin natif : compatible Flutter Web.
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Version disponible renvoyée par le backend.
class AppVersionInfo {
  final String id;
  final String version;
  final int buildNumber;
  final String plateforme;
  final String? apkUrl;
  final int? tailleOctets;
  final String notes;
  final DateTime datePublication;
  final bool obligatoire;

  AppVersionInfo({
    required this.id,
    required this.version,
    required this.buildNumber,
    required this.plateforme,
    this.apkUrl,
    this.tailleOctets,
    required this.notes,
    required this.datePublication,
    required this.obligatoire,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> j) {
    return AppVersionInfo(
      id: j['id'] as String? ?? '',
      version: j['version'] as String? ?? '',
      buildNumber:
          (j['buildNumber'] as num?)?.toInt() ??
          int.tryParse('${j['buildNumber'] ?? 0}') ??
          0,
      plateforme: j['plateforme'] as String? ?? '',
      apkUrl: j['apkUrl'] as String?,
      tailleOctets: (j['tailleOctets'] as num?)?.toInt(),
      notes: j['notes'] as String? ?? '',
      datePublication:
          DateTime.tryParse(j['datePublication'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      obligatoire: j['obligatoire'] as bool? ?? false,
    );
  }

  /// Taille lisible, ex. « 55,0 Mo ».
  String get tailleLisible {
    if (tailleOctets == null) return '';
    final mo = tailleOctets! / (1024 * 1024);
    return '${mo.toStringAsFixed(1)} Mo';
  }
}

class UpdateService {
  /// Version installée (sync avec pubspec.yaml : 1.0.1+2).
  ///
  /// À mettre à jour en même temps que pubspec.yaml lors d'une release :
  /// `version: X.Y.Z+N` → versionInstallee = 'X.Y.Z', buildInstalle = N.
  static const String versionInstallee = '1.0.1';
  static const int buildInstalle = 2;

  /// Récupère la dernière version active pour la plateforme courante.
  static Future<AppVersionInfo?> verifierDerniereVersion() async {
    final plateforme = kIsWeb ? 'web' : 'android';
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/versions/latest')
          .replace(queryParameters: {'plateforme': plateforme});
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Une réponse "null" (aucune version active) n'est pas une mise à jour.
        if (data.isEmpty) return null;
        return AppVersionInfo.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Y a-t-il une mise à jour disponible ?
  ///
  /// On compare le buildNumber ET la version lisible : publier "1.0.1" avec
  /// le même build que l'app installée doit tout de même proposer la mise à jour.
  static bool miseAJourDisponible(AppVersionInfo? distante) {
    if (distante == null) return false;
    if (distante.buildNumber > buildInstalle) return true;
    if (distante.buildNumber < buildInstalle) return false;
    return _estSuperieure(distante.version, versionInstallee);
  }

  /// Compare des versions du type "1.0.1", "1.2", "2.0.0+3".
  static bool _estSuperieure(String distante, String installee) {
    final a = _parties(distante);
    final b = _parties(installee);
    final n = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < n; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x > y) return true;
      if (x < y) return false;
    }
    return false;
  }

  /// Le suffixe "+N" est un numéro de build, pas un segment de version :
  /// "1.0.0+2" doit se comparer comme "1.0.0".
  static List<int> _parties(String v) => v
      .split('+')
      .first
      .split(RegExp(r'[^0-9]+'))
      .where((s) => s.isNotEmpty)
      .map((s) => int.tryParse(s) ?? 0)
      .toList();
}
