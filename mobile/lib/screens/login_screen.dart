import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../widgets/google_logo.dart';
import 'register_screen.dart';
import 'otp_screen.dart';
import 'contact_urgence_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();
  String? _erreur;
  bool _chargement = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isEmail(String text) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text);
  }

  Future<void> _continuer() async {
    final text = _controller.text.trim();

    if (!_isEmail(text)) {
      setState(() => _erreur = 'Email invalide');
      return;
    }

    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final user = await ApiService.findByEmail(text);

      if (!mounted) return;
      if (user == null) {
        setState(() {
          _erreur = 'Aucun compte avec cet identifiant. Cree un compte d\'abord.';
          _chargement = false;
        });
        return;
      }

      await ApiService.envoyerCodeOtpEmail(text);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            telephone: text,
            userId: user['id'] as String? ?? '',
            prenom: user['prenom'] as String? ?? '',
            useEmail: true,
          ),
        ),
      ).then((_) {
        if (mounted) setState(() => _chargement = false);
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

  // === GOOGLE SIGN IN ===
  Future<void> _signInWithGoogle() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final googleUser = await GoogleSignIn(
        scopes: ['email', 'profile'],
      ).signIn();
      if (googleUser == null) {
        setState(() => _chargement = false);
        return;
      }
      final result = await ApiService.googleLogin(
        googleId: googleUser.id,
        email: googleUser.email,
        prenom: googleUser.displayName?.split(' ').first ?? '',
        nom: googleUser.displayName?.split(' ').skip(1).join(' ') ?? '',
        photoUrl: googleUser.photoUrl,
      );

      if (!mounted) return;
      final userId = result['id'] as String;
      final prenom = result['prenom'] as String;
      final isNew = result['isNew'] as bool;

      await Session.sauver(userId, prenom);

      if (isNew) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ContactUrgenceScreen(userId: userId, invitation: true),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ContactUrgenceScreen(userId: userId, invitation: true),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Connexion Google impossible : $e';
        _chargement = false;
      });
    }
  }

  // === APPLE SIGN IN ===
  Future<void> _signInWithApple() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      String prenom = '';
      String nom = '';
      if (credential.givenName != null) prenom = credential.givenName!;
      if (credential.familyName != null) nom = credential.familyName!;

      final result = await ApiService.appleLogin(
        appleId: credential.userIdentifier ?? '',
        email: credential.email,
        prenom: prenom.isNotEmpty ? prenom : null,
        nom: nom.isNotEmpty ? nom : null,
      );

      if (!mounted) return;
      final userId = result['id'] as String;
      final userPrenom = result['prenom'] as String;
      final isNew = result['isNew'] as bool;

      await Session.sauver(userId, userPrenom);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ContactUrgenceScreen(userId: userId, invitation: true),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Connexion Apple impossible';
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Connexion')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Bon retour !',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Connectez-vous avec Google, Apple ou votre email.',
              style: TextStyle(fontSize: 14, color: kTextSecondary),
            ),
            const SizedBox(height: 28),

            // === BOUTONS GOOGLE / APPLE ===
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _chargement ? null : _signInWithGoogle,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kTextPrimary,
                  side: const BorderSide(color: kBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GoogleLogo(size: 20),
                    SizedBox(width: 10),
                    Text('Continuer avec Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (!Platform.isAndroid)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _chargement ? null : _signInWithApple,
                  icon: const Icon(Icons.apple_rounded, size: 24),
                  label: const Text('Continuer avec Apple', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kTextPrimary,
                    side: const BorderSide(color: kBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Separateur
            Row(
              children: [
                Expanded(child: Divider(color: kBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('ou', style: TextStyle(fontSize: 13, color: kTextSecondary)),
                ),
                Expanded(child: Divider(color: kBorder)),
              ],
            ),

            const SizedBox(height: 24),

            // Champ email uniquement
            TextField(
              controller: _controller,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'exemple@domaine.com',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
            ),

            if (_erreur != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kRedLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kRed.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: kRed, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _erreur!,
                        style: const TextStyle(
                          color: kRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _chargement ? null : _continuer,
                child: _chargement
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Continuer'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: Text.rich(
                  TextSpan(
                    text: 'Pas encore de compte ? ',
                    style: TextStyle(color: kTextSecondary, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Creer un compte',
                        style: TextStyle(
                          color: kOrange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
