import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'main_scaffold.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();
  bool _useEmail = false;
  String? _erreur;
  bool _chargement = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continuer() async {
    final text = _controller.text.trim().replaceAll(' ', '');

    if (_useEmail) {
      final isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text);
      if (!isEmail) {
        setState(() => _erreur = 'Email invalide');
        return;
      }
    } else {
      final isPhone = RegExp(r'^[0-9]{8}$').hasMatch(text);
      if (!isPhone) {
        setState(() => _erreur = 'Numéro de téléphone invalide (8 chiffres)');
        return;
      }
    }

    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final user = await (_useEmail
          ? ApiService.findByEmail(text)
          : ApiService.findByTelephone(text));

      if (!mounted) return;
      if (user == null) {
        setState(() {
          _erreur = 'Aucun compte avec cet identifiant. Crée un compte d\'abord.';
          _chargement = false;
        });
        return;
      }
      await Session.sauver(
          user['id'] as String? ?? '', user['prenom'] as String? ?? '');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScaffold(
            userId: user['id'] as String? ?? '',
            prenom: user['prenom'] as String? ?? '',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _erreur = 'Connexion au serveur impossible';
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
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
              'Entrez votre numéro de téléphone ou votre email.',
              style: TextStyle(fontSize: 14, color: kTextSecondary),
            ),
            const SizedBox(height: 28),

            // Toggle chips
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: kGreyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _useEmail = false;
                        _controller.clear();
                        _erreur = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_useEmail ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !_useEmail
                              ? [BoxShadow(color: kCardShadow, blurRadius: 8, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 18,
                              color: !_useEmail ? kOrange : kTextSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Téléphone',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: !_useEmail ? kOrange : kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _useEmail = true;
                        _controller.clear();
                        _erreur = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _useEmail ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _useEmail
                              ? [BoxShadow(color: kCardShadow, blurRadius: 8, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: _useEmail ? kOrange : kTextSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _useEmail ? kOrange : kTextSecondary,
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

            const SizedBox(height: 24),

            // Input field
            TextField(
              controller: _controller,
              keyboardType: _useEmail ? TextInputType.emailAddress : TextInputType.phone,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: _useEmail ? 'Email' : 'Numéro de téléphone',
                prefixText: _useEmail ? null : '+223  ',
                hintText: _useEmail ? 'exemple@domaine.com' : '70 12 34 56',
                prefixIcon: Icon(
                  _useEmail ? Icons.email_outlined : Icons.phone_outlined,
                  size: 20,
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
            // Register link
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
                        text: 'Créer un compte',
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
