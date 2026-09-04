import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'otp_screen.dart';
import 'login_screen.dart';

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
            telephone: user['email'] as String? ?? '',
            userId: user['id'] as String,
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
        _erreur = 'Impossible de joindre le serveur. Vérifie ta connexion.';
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Bienvenue !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ton numéro de téléphone est ton identifiant unique.',
                style: TextStyle(fontSize: 14, color: kTextSecondary),
              ),
              const SizedBox(height: 28),
              _buildField(
                controller: _prenom,
                label: 'Prénom',
                icon: Icons.person_outline_rounded,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Le prénom est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _nom,
                label: 'Nom',
                icon: Icons.badge_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Le nom est obligatoire' : null,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              _buildField(
                controller: _quartier,
                label: 'Quartier principal',
                icon: Icons.location_on_outlined,
                hintText: 'Kalaban Coro',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Le quartier est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _email,
                label: 'Email',
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
              if (_erreur != null) ...[
                const SizedBox(height: 16),
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
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
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
                      : const Text('Recevoir mon code'),
              ),
            ),
            const SizedBox(height: 16),
            // Login link
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
            const SizedBox(height: 32),
            ],
          ),
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
