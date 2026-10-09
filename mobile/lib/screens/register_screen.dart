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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(230),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: kTextPrimary, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Créer un compte',
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
                          'Remplis tes infos ou inscris-toi avec ton compte social.',
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
                            child: Text('Ou inscris-toi avec', style: TextStyle(fontSize: 12, color: kTextSecondary)),
                          ),
                          const Expanded(child: Divider(color: kBorder)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildField(controller: _prenom, label: 'Prénom', hintText: 'Ex. Awa',
                              validator: (v) => v == null || v.trim().isEmpty ? 'Le prénom est obligatoire' : null),
                            const SizedBox(height: 12),
                            _buildField(controller: _nom, label: 'Nom', hintText: 'Ex. Traoré',
                              validator: (v) => v == null || v.trim().isEmpty ? 'Le nom est obligatoire' : null),
                            const SizedBox(height: 12),
                            _buildField(controller: _telephone, label: 'Numéro de téléphone', hintText: '70 12 34 56',
                              prefixText: '+223  ', keyboardType: TextInputType.phone, maxLength: 8,
                              validator: (v) {
                                final chiffres = v?.replaceAll(' ', '') ?? '';
                                if (chiffres.length != 8) return 'Le numéro doit contenir 8 chiffres';
                                return null;
                              }),
                            const SizedBox(height: 12),
                            _buildField(controller: _quartier, label: 'Quartier principal', hintText: 'Ex. Kalaban Coro',
                              validator: (v) => v == null || v.trim().isEmpty ? 'Le quartier est obligatoire' : null),
                            const SizedBox(height: 12),
                            _buildField(controller: _email, label: 'Email', hintText: 'exemple@domaine.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                final email = v ?? '';
                                if (!email.contains('@') || !email.contains('.')) return 'Email invalide';
                                return null;
                              }),
                          ],
                        ),
                      ),
                      if (_erreur != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: kRedLight, borderRadius: BorderRadius.circular(10)),
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
                          onPressed: _chargement ? null : _envoyerCode,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          ),
                          child: _chargement
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Text('S\'inscrire', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: 'Déjà un compte ? ',
                              style: TextStyle(color: kTextSecondary, fontSize: 13),
                              children: const [
                                TextSpan(text: 'Se connecter', style: TextStyle(color: kOrange, fontWeight: FontWeight.w700)),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? prefixText,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF4F2EC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kOrange, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kRed)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kRed, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
