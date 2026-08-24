import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  /// 10.0.2.2 = localhost du PC depuis l'émulateur Android.
  /// Sur un vrai téléphone, mettre l'IP locale du PC (ex. 192.168.1.12).
  static const String baseUrl = 'http://10.0.2.2:3000';

  static Future<Map<String, dynamic>> register({
    required String prenom,
    required String nom,
    required String telephone,
    required String quartier,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prenom': prenom,
        'nom': nom,
        'telephone': telephone,
        'quartier': quartier,
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
    if (response.statusCode == 404) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return body;
    }
    throw ApiException(_messageErreur(body) ?? 'Erreur de recherche');
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
