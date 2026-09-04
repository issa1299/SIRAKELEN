import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Session locale : l'utilisateur reste connecté entre les ouvertures.
class Session {
  static const _kUserId = 'session_user_id';
  static const _kPrenom = 'session_prenom';

  static Future<void> sauver(String userId, String prenom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, userId);
    await prefs.setString(_kPrenom, prenom);
  }

  static Future<({String userId, String prenom})?> lire() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kUserId);
    if (id == null || id.isEmpty) return null;
    return (userId: id, prenom: prefs.getString(_kPrenom) ?? '');
  }

  static Future<void> effacer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kPrenom);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  /// IP locale du PC de développement (même Wi-Fi obligatoire).
  /// - Émulateur Android : 10.0.2.2 = localhost du PC
  /// - Vrai téléphone : l'IP locale du PC (ex. 192.168.1.204)
  /// Tunnel ADB (adb reverse tcp:8080 tcp:8080) : le téléphone appelle
  /// localhost:8080 qui est redirigé vers le PC. Fonctionne quel que soit
  /// le Wi-Fi, sans pare-feu.
  static const String baseUrl = 'http://192.168.1.113:8080';

  static Future<Map<String, dynamic>> register({
    required String prenom,
    required String nom,
    required String telephone,
    required String quartier,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prenom': prenom,
        'nom': nom,
        'telephone': telephone,
        'quartier': quartier,
        'email': email,
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201) {
      return body;
    }
    throw ApiException(_messageErreur(body) ?? 'Erreur lors de l’inscription');
  }

  static Future<Map<String, dynamic>?> findByTelephone(String telephone) async {
    final normalise = telephone.replaceAll(' ', '');
    final response = await http.post(
      Uri.parse('$baseUrl/users/recherche'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'telephone': normalise}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Compte introuvable : l'API renvoie un corps vide.
      if (response.body.isEmpty) return null;
      final body = jsonDecode(response.body);
      if (body == null) return null;
      return body as Map<String, dynamic>;
    }
    final erreur = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    throw ApiException(_messageErreur(erreur) ?? 'Erreur de recherche');
  }

  static Future<void> envoyerCodeOtp(String telephone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/envoyer-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'telephone': telephone.replaceAll(' ', '')}),
    );
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(_messageErreur(body) ?? 'Envoi du code impossible');
  }

  static Future<void> verifierCodeOtp(String telephone, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verifier'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'telephone': telephone.replaceAll(' ', ''),
        'code': code,
      }),
    );
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(_messageErreur(body) ?? 'Code incorrect');
  }

  // === NOUVEAUX : Email ===
  static Future<Map<String, dynamic>?> findByEmail(String email) async {
    final normalise = email.toLowerCase().trim();
    final response = await http.post(
      Uri.parse('$baseUrl/users/recherche'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': normalise}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      final body = jsonDecode(response.body);
      if (body == null) return null;
      return body as Map<String, dynamic>;
    }
    throw ApiException('Recherche par email impossible');
  }

  static Future<void> envoyerCodeOtpEmail(String email) async {
    final normalise = email.toLowerCase().trim();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/envoyer-code-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': normalise}),
    );
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(_messageErreur(body) ?? 'Envoi du code par email impossible');
  }

  static Future<void> verifierCodeOtpEmail(String email, String code) async {
    final normalise = email.toLowerCase().trim();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verifier-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': normalise,
        'code': code,
      }),
    );
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(_messageErreur(body) ?? 'Code incorrect par email');
  }

  static Future<Map<String, dynamic>> publierAd({
    required String userId,
    required String role,
    required String depart,
    required String destination,
    required String dateDeplacement,
    required String heureDepart,
    String? moyenTransport,
    int? placesDisponibles,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ads'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'role': role,
        'depart': depart,
        'destination': destination,
        'dateDeplacement': dateDeplacement,
        'heureDepart': heureDepart,
        'moyenTransport': ?moyenTransport,
        'placesDisponibles': ?placesDisponibles,
      }),
    );
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if (response.statusCode == 201) {
      return body;
    }
    throw ApiException(_messageErreur(body) ?? 'Publication impossible');
  }

  static Future<List<dynamic>> mesAds(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/ads/mine/$userId'));
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  static Future<void> envoyerDemande(String adId, String demandeurId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/demandes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'adId': adId, 'demandeurId': demandeurId}),
    );
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if (response.statusCode == 201) return;
    throw ApiException(_messageErreur(body) ?? 'Envoi impossible');
  }

  static Future<List<dynamic>> getDemandesRecues(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/demandes/recues/$userId'));
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  static Future<void> accepterDemande(String demandeId, String userId) async {
    final r = await http.post(
        Uri.parse('$baseUrl/demandes/$demandeId/accepter/$userId'));
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    final body = r.body.isNotEmpty
        ? jsonDecode(r.body) as Map<String, dynamic>
        : <String, dynamic>{};
    throw ApiException(_messageErreur(body) ?? 'Acceptation impossible');
  }

  static Future<void> refuserDemande(String demandeId, String userId) async {
    final r = await http.post(
        Uri.parse('$baseUrl/demandes/$demandeId/refuser/$userId'));
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    final body = r.body.isNotEmpty
        ? jsonDecode(r.body) as Map<String, dynamic>
        : <String, dynamic>{};
    throw ApiException(_messageErreur(body) ?? 'Refus impossible');
  }

  static Future<void> marquerOrganise(String adId, String userId) async {
    final r = await http.post(
        Uri.parse('$baseUrl/demandes/ads/$adId/organise/$userId'));
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    final body = r.body.isNotEmpty
        ? jsonDecode(r.body) as Map<String, dynamic>
        : <String, dynamic>{};
    throw ApiException(_messageErreur(body) ?? 'Action impossible');
  }

  static Future<List<dynamic>> getDemandesEnvoyees(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/demandes/envoyees/$userId'));
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  static Future<void> annulerDemande(String demandeId, String userId) async {
    final r = await http.post(
        Uri.parse('$baseUrl/demandes/$demandeId/annuler/$userId'));
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    final body = r.body.isNotEmpty
        ? jsonDecode(r.body) as Map<String, dynamic>
        : <String, dynamic>{};
    throw ApiException(_messageErreur(body) ?? 'Annulation impossible');
  }

  static Future<void> definirContactUrgence({
    required String userId,
    required String nomContact,
    required String telephoneContact,
    String? lien,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/securite/contact-urgence'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'nomContact': nomContact,
        'telephoneContact': telephoneContact.replaceAll(' ', ''),
        'lien': ?lien,
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    throw ApiException(_messageErreur(body) ?? 'Enregistrement impossible');
  }

  static Future<Map<String, dynamic>?> getContactUrgence(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/securite/contact-urgence/$userId'));
    if (response.statusCode == 200 &&
        response.body.isNotEmpty &&
        response.body != 'null') {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<Map<String, dynamic>> getStats(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/securite/stats/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {'adPublies': 0, 'trajetsOrganises': 0, 'signalements': 0};
  }

  static Future<void> signaler({
    required String signaleUserId,
    required String auteurId,
    required String motif,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/securite/signalements'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'signaleUserId': signaleUserId,
        'auteurId': auteurId,
        'motif': motif,
      }),
    );
    if (response.statusCode == 201) return;
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    throw ApiException(_messageErreur(body) ?? 'Signalement impossible');
  }

  static Future<List<dynamic>> getTrajetsPublics(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/ads/publiques/$userId'));
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  static Future<List<dynamic>> getCompatibilites(String userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/ads/compatibilites/$userId'));
    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  static Future<void> annulerAd(String adId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ads/$adId/annuler/$userId'),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    throw ApiException(_messageErreur(body) ?? 'Annulation impossible');
  }

  static Future<Map<String, dynamic>> marquerVerifie(String id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/$id/verifier'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Impossible de marquer le profil vérifié');
  }

  static Future<Map<String, dynamic>> getUser(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$id'));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return body;
    }
    throw ApiException(_messageErreur(body) ?? 'Utilisateur introuvable');
  }

  static Future<Map<String, dynamic>> updateProfil(
    String id, {
    String? prenom,
    String? nom,
    String? quartier,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prenom': ?prenom,
        'nom': ?nom,
        'quartier': ?quartier,
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return body;
    }
    throw ApiException(_messageErreur(body) ?? 'Erreur de mise à jour');
  }

  // === CODE DE RÉCUPÉRATION ===
  static Future<void> definirCodeRecuperation(String telephone, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/definir-code-recuperation'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'telephone': telephone, 'codeRecuperation': code}),
    );
    if (response.statusCode == 200) return;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw ApiException(_messageErreur(body) ?? 'Erreur lors de l\'enregistrement du code');
  }

  static Future<Map<String, dynamic>> verifierCodeRecuperation(String telephone, String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verifier-code-recuperation'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'telephone': telephone, 'codeRecuperation': code}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) return body;
    throw ApiException(_messageErreur(body) ?? 'Code de récupération incorrect');
  }

  static String? _messageErreur(Map<String, dynamic> body) {
    final message = body['message'];
    if (message is List && message.isNotEmpty) {
      return message.first.toString();
    }
    if (message is String) {
      return message;
    }
    return null;
  }
}
