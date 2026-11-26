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
  /// Version installée (sync avec pubspec.yaml : 1.0.0+1).
  static const String versionInstallee = '1.0.0';
  static const int buildInstalle = 1;

  /// Récupère la dernière version active pour la plateforme courante.
  static Future<AppVersionInfo?> verifierDerniereVersion() async {
    final plateforme = kIsWeb ? 'web' : 'android';
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/versions/latest')
          .replace(queryParameters: {'plateforme': plateforme});
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AppVersionInfo.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Y a-t-il une mise à jour disponible ?
  static bool miseAJourDisponible(AppVersionInfo? distante) {
    if (distante == null) return false;
    return distante.buildNumber > buildInstalle;
  }
}
