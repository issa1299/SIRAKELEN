import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'welcome_screen.dart';

/// Carrousel de 3 slides au premier lancement :
/// économies / fonctionnement / confiance.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _suivant() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _terminer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_vu', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _Slide1(onSuivant: _suivant),
                _Slide2(onSuivant: _suivant),
                _Slide3(onTerminer: _terminer),
              ],
            ),
            if (_page < 2)
              Positioned(
                top: 8,
                right: 16,
                child: TextButton(
                  onPressed: _terminer,
                  child: const Text('Passer',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlideBase extends StatelessWidget {
  final IconData icone;
  final String surtitre;
  final String titre;
  final String description;
  final int page;
  final VoidCallback? surDernier;
  final VoidCallback? onSuivant;

  const _SlideBase({
    required this.icone,
    required this.surtitre,
    required this.titre,
    required this.description,
    required this.page,
    this.surDernier,
    this.onSuivant,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(        children: [
          const Spacer(flex: 2),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E6),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFFDFC0)),
            ),
            child: Icon(icone, size: 52, color: kOrangeDark),
          ),
          const SizedBox(height: 30),
          Text(surtitre.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: kOrangeDark)),
          const SizedBox(height: 10),
          Text(titre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, height: 1.3)),
          const SizedBox(height: 12),
          Text(description,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey.shade600,
                  height: 1.6)),
          const Spacer(flex: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final actif = i == page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: actif ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: actif ? kOrange : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          if (surDernier != null) ...[
            FilledButton(
              onPressed: surDernier,
              child: const Text('Créer mon compte'),
            ),
            TextButton(
              onPressed: surDernier,
              child: const Text('J’ai déjà un compte',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: kOrangeDark)),
            ),
          ] else
            FilledButton(
              onPressed: onSuivant,
              child: const Text('Suivant'),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

}

class _Slide1 extends StatelessWidget {
  final VoidCallback onSuivant;
  const _Slide1({required this.onSuivant});

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      icone: Icons.savings_outlined,
      surtitre: 'Voyagez mieux. Dépensez moins.',
      titre: 'Réduisez vos frais de transport au quotidien.',
      description:
          'Partagez les coûts de déplacement avec des personnes qui effectuent un trajet similaire au vôtre.',
      page: 0,
      onSuivant: onSuivant,
    );
  }
}

class _Slide2 extends StatelessWidget {
  final VoidCallback onSuivant;
  const _Slide2({required this.onSuivant});

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      icone: Icons.auto_awesome,
      surtitre: 'Publication simple. Matching intelligent.',
      titre: 'Publiez votre trajet, nous trouvons les correspondances.',
      description:
          'Déposez un avis de déplacement en quelques secondes. Le système identifie automatiquement les utilisateurs dont l’itinéraire est compatible avec le vôtre.',
      page: 1,
      onSuivant: onSuivant,
    );
  }
}

class _Slide3 extends StatelessWidget {
  final VoidCallback onTerminer;
  const _Slide3({required this.onTerminer});

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      icone: Icons.verified_user_outlined,
      surtitre: 'Sécurité, confiance et liberté de choix.',
      titre: 'Des trajets partagés en toute confiance.',
      description:
          'Chaque utilisateur est vérifié par numéro de téléphone. Vous choisissez librement avec qui partager votre trajet.',
      page: 2,
      surDernier: onTerminer,
    );
  }
}
