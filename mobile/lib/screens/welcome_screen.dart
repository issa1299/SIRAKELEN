import 'package:flutter/material.dart';
import '../main.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Logo hero
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: kOrange.withAlpha(60),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/logo-sk.png',
                        fit: BoxFit.contain,
                      ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Titre
                    const Text(
                      'Partagez la route.\nPartagez le coût.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        letterSpacing: -0.5,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Le covoiturage urbain pensé pour Bamako : trajets compatibles, prix divisés, voyageurs vérifiés.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: kTextSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Atouts
                    _atout(
                      icone: Icons.route_rounded,
                      titre: 'Matching intelligent',
                      texte: 'Conducteurs et passagers compatibles, trouvés automatiquement.',
                    ),
                    const SizedBox(height: 10),
                    _atout(
                      icone: Icons.verified_rounded,
                      titre: 'Comptes vérifiés',
                      texte: 'Email ou Google, profils contrôlés avant chaque trajet.',
                    ),
                    const SizedBox(height: 10),
                    _atout(
                      icone: Icons.savings_outlined,
                      titre: 'Frais divisés',
                      texte: 'Partagez le coût du transport, économisez chaque jour.',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // CTA fixes en bas
            Container(
              padding: const EdgeInsets.fromLTRB(28, 14, 28, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                        child: const Text('Créer mon compte'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kOrange, width: 1.5),
                        ),
                        child: const Text(
                          'J\'ai déjà un compte',
                          style: TextStyle(color: kOrange),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _atout({required IconData icone, required String titre, required String texte}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kOrangeLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: kOrange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(texte, style: TextStyle(fontSize: 12, color: kTextSecondary, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
