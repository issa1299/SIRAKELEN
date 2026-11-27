import 'package:shared_preferences/shared_preferences.dart';

/// Mémorise les notifications déjà consultées afin que le badge de la cloche
/// disparaisse après lecture, même si la demande reste en attente côté serveur.
class NotificationReadService {
  static const _cle = 'notifications_lues';

  static Future<Set<String>> _lues() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_cle) ?? []).toSet();
  }

  static Future<bool> estLue(String id) async {
    if (id.isEmpty) return false;
    return (await _lues()).contains(id);
  }

  static Future<void> marquerCommeLues(Iterable<String> ids) async {
    final aMarquer = ids.where((e) => e.isNotEmpty).toSet();
    if (aMarquer.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final toutes = (prefs.getStringList(_cle) ?? []).toSet()..addAll(aMarquer);
    await prefs.setStringList(_cle, toutes.take(500).toList());
  }

  /// Filtre les éléments non encore consultés (utilisé pour le badge).
  static Future<List<Map<String, dynamic>>> nonLues(
    List<Map<String, dynamic>> elements,
  ) async {
    final lues = await _lues();
    return elements.where((e) => !lues.contains(e['id'] as String? ?? '')).toList();
  }
}
