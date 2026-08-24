import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Vérification du numéro par SMS via Firebase Phone Auth.
/// Renvoie l'identifiant Firebase (uid) si le code est correct.
class AuthService {
  /// Mis à true dans main.dart quand Firebase.initializeApp() réussit.
  static bool firebaseDisponible = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Étape 1 : envoyer le code SMS au numéro.
  /// [codeEnvoye] est appelé quand le SMS part.
  /// [erreur] est appelé en cas d'échec.
  Future<void> envoyerCode({
    required String telephone,
    required void Function(String verificationId) codeEnvoye,
    required void Function(String message) erreur,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+223$telephone',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android : saisie automatique du SMS.
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        erreur(_messageLisible(e));
      },
      codeSent: (String verificationId, int? resendToken) {
        codeEnvoye(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Étape 2 : vérifier le code saisi par l'utilisateur.
  Future<String> verifierCode({
    required String verificationId,
    required String code,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user?.uid ?? '';
  }

  String _messageLisible(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Numéro de téléphone invalide';
      case 'invalid-verification-code':
        return 'Code incorrect';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie plus tard.';
      case 'operation-not-allowed':
        return 'La connexion par téléphone n’est pas activée dans Firebase';
      default:
        if (kDebugMode) {
          return 'Erreur Firebase : ${e.code}';
        }
        return 'Vérification impossible pour le moment';
    }
  }
}
