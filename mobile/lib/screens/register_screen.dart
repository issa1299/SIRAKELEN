import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'otp_screen.dart';

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
  bool _chargement = false;
  String? _erreur;

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _telephone.dispose();
    _quartier.dispose();
    super.dispose();
  }

  Future<void> _envoyerCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      // TODO Phase 2 : envoyer le code SMS via Firebase avant de continuer.
      final user = await ApiService.register(
        prenom: _prenom.text.trim(),
        nom: _nom.text.trim(),
        telephone: _telephone.text.trim(),
        quartier: _quartier.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            telephone: user['telephone'] as String,
            userId: user['id'] as String,
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
        _erreur =
            'Impossible de joindre le serveur. Vérifie ta connexion (10.0.2.2:3000).';
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer mon compte'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bienvenue !',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Ton numéro de téléphone est ton identifiant unique.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _prenom,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Le prénom est obligatoire' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nom,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Le nom est obligatoire' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _telephone,
                keyboardType: TextInputType.phone,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixText: '+223  ',
                  counterText: '',
                  hintText: '70 12 34 56',
                ),
                validator: (v) {
                  final chiffres = v?.replaceAll(' ', '') ?? '';
                  if (chiffres.length != 8) {
                    return 'Le numéro doit contenir 8 chiffres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _quartier,
                decoration: const InputDecoration(
                  labelText: 'Quartier principal',
                  hintText: 'Kalaban Coro',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Le quartier est obligatoire' : null,
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _erreur!,
                    style: const TextStyle(color: Color(0xFFA3392F), fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
