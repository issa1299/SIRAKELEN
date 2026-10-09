import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../main.dart';
import '../services/api_service.dart';
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
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero orange
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 28,
                  right: 28,
                  bottom: 64,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kOrange, kOrangeDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -60,
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -70,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(40),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset('assets/logo-sk.png', fit: BoxFit.contain),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Bon retour !',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Heureux de te revoir, ton prochain trajet t\'attend.',
                          style: TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Carte formulaire chevauchante
              Transform.translate(
                offset: const Offset(0, -40),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pastilles sociales
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _pastilleSocial(
                            onTap: _chargement ? null : _signInWithGoogle,
                            enfant: Image.asset('assets/googlelogo.webp', width: 22, height: 22),
                          ),
                          if (!Platform.isAndroid) ...[
                            const SizedBox(width: 14),
                            _pastilleSocial(
                              onTap: _chargement ? null : _signInWithApple,
                              enfant: const Icon(Icons.apple_rounded, size: 24, color: kTextPrimary),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: kBorder)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Ou connecte-toi avec', style: TextStyle(fontSize: 12, color: kTextSecondary)),
                          ),
                          const Expanded(child: Divider(color: kBorder)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextPrimary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _controller,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'exemple@domaine.com',
                          filled: true,
                          fillColor: const Color(0xFFF4F2EC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kOrange, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      if (_erreur != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kRedLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: kRed, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_erreur!, style: const TextStyle(color: kRed, fontSize: 12, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _chargement ? null : _continuer,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          ),
                          child: _chargement
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text('Se connecter', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: 'Pas encore de compte ? ',
                              style: TextStyle(color: kTextSecondary, fontSize: 13),
                              children: const [
                                TextSpan(
                                  text: 'Créer un compte',
                                  style: TextStyle(color: kOrange, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pastilleSocial({required VoidCallback? onTap, required Widget enfant}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Center(child: enfant),
      ),
    );
  }
}
