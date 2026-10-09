import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'otp_screen.dart';
import 'login_screen.dart';
import 'contact_urgence_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  final _quartier = TextEditingController();
  final _email = TextEditingController();
  bool _chargement = false;
  String? _erreur;

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _telephone.dispose();
    _quartier.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _envoyerCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final user = await ApiService.register(
        prenom: _prenom.text.trim(),
        nom: _nom.text.trim(),
        telephone: _telephone.text.trim(),
        quartier: _quartier.text.trim(),
        email: _email.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            telephone: _email.text.trim(),
            userId: '',
            prenom: user['prenom'] as String? ?? '',
            useEmail: true,
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    } catch (_) {
      setState(() {
        _erreur = 'Impossible de joindre le serveur. Verifie ta connexion.';
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

      await Session.sauver(userId, prenom);
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
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            // Logo + titre
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kOrange.withAlpha(50),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/logo-officiel.png', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rejoins SIRA KELEN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '30 secondes pour créer ton compte, gratuitement.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kTextSecondary),
            ),
            const SizedBox(height: 24),

            // === BOUTONS GOOGLE / APPLE ===
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _chargement ? null : _signInWithGoogle,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kTextPrimary,
                  side: const BorderSide(color: kBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/googlelogo.webp', width: 20, height: 20),
                    const SizedBox(width: 10),
                    const Text('S\'inscrire avec Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (!Platform.isAndroid)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _chargement ? null : _signInWithApple,
                  icon: const Icon(Icons.apple_rounded, size: 22),
                  label: const Text('S\'inscrire avec Apple', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kTextPrimary,
                    side: const BorderSide(color: kBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            if (!Platform.isAndroid) const SizedBox(height: 4),

            const SizedBox(height: 20),

            // Separateur
            Row(
              children: [
                const Expanded(child: Divider(color: kBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('ou avec tes infos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextSecondary)),
                ),
                const Expanded(child: Divider(color: kBorder)),
              ],
            ),

            const SizedBox(height: 20),

            // Carte formulaire
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kBorder),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildField(
                      controller: _prenom,
                      label: 'Prénom',
                      icon: Icons.person_outline_rounded,
                      hintText: 'Ex. Awa',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Le prénom est obligatoire' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _nom,
                      label: 'Nom',
                      icon: Icons.badge_outlined,
                      hintText: 'Ex. Traoré',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Le nom est obligatoire' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _telephone,
                      label: 'Numéro de téléphone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      maxLength: 8,
                      prefixText: '+223  ',
                      hintText: '70 12 34 56',
                      validator: (v) {
                        final chiffres = v?.replaceAll(' ', '') ?? '';
                        if (chiffres.length != 8) {
                          return 'Le numéro doit contenir 8 chiffres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _quartier,
                      label: 'Quartier principal',
                      icon: Icons.location_on_outlined,
                      hintText: 'Ex. Kalaban Coro',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Le quartier est obligatoire' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _email,
                      label: 'Adresse email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'exemple@domaine.com',
                      validator: (v) {
                        final email = v ?? '';
                        if (!email.contains('@') || !email.contains('.')) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _chargement ? null : _envoyerCode,
                        child: _chargement
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Recevoir mon code'),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
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
                        style: const TextStyle(color: kRed, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: Text.rich(
                  TextSpan(
                    text: 'Déjà un compte ? ',
                    style: TextStyle(color: kTextSecondary, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Se connecter',
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    String? prefixText,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixText: prefixText,
        counterText: '',
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: validator,
    );
  }
}
