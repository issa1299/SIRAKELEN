import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'otp_screen.dart';

class CodeOublieScreen extends StatefulWidget {
  const CodeOublieScreen({super.key});

  @override
  State<CodeOublieScreen> createState() => _CodeOublieScreenState();
}

class _CodeOublieScreenState extends State<CodeOublieScreen> {
  final _phoneController = TextEditingController();
  bool _chargement = false;
  String? _erreur;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _envoyerCode() async {
    final text = _phoneController.text.trim().replaceAll(' ', '');
    if (text.length != 8 || !RegExp(r'^[0-9]{8}$').hasMatch(text)) {
      setState(() => _erreur = 'Numéro de téléphone invalide');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await ApiService.envoyerCodeOtp(text);
      if (!mounted) return;
      setState(() {
        _chargement = false;
      });
      // Navigate to OTP screen for verification, then recovery code creation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            telephone: text,
            userId: '',
            prenom: '',
            useEmail: false,
            isCodeOublie: true,
          ),
        ),
      );
    } catch (_) {
      setState(() {
        _erreur = 'Impossible d\'envoyer le code. Vérifie ta connexion.';
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Code oublié')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 2),
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kOrange,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 28),
            const Text(
              'Pas de panique',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nous allons renvoyer un code de vérification par SMS pour confirmer votre identité, puis vous pourrez créer un nouveau code de récupération.',
              style: TextStyle(fontSize: 14, color: kTextSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            const Text(
              'Numéro de téléphone',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 72,
                  height: 52,
                  decoration: BoxDecoration(
                    color: kGreyLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '+223',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      hintText: '70 12 34 56',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                ),
              ],
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
            const Spacer(flex: 3),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _chargement ? null : _envoyerCode,
                child: _chargement
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Recevoir un code par SMS'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
