import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'welcome_screen.dart';

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
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
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
      backgroundColor: kCream,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              physics: const BouncingScrollPhysics(),
              children: [
                _Slide(
                  icon: Icons.savings_rounded,
                  title: 'Réduisez vos frais de transport',
                  description:
                      'Partagez les coûts de déplacement avec des personnes qui effectuent un trajet similaire au vôtre.',
                  gradient: [kOrange, const Color(0xFFFF9A3E)],
                  page: 0,
                  total: 3,
                  onTap: _suivant,
                  onSkip: _terminer,
                  showLogo: true,
                ),
                _Slide(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Matching intelligent',
                  description:
                      'Publiez votre trajet en quelques secondes. Le système identifie automatiquement les utilisateurs compatibles.',
                  gradient: [const Color(0xFFE25F00), kOrange],
                  page: 1,
                  total: 3,
                  onTap: _suivant,
                  onSkip: _terminer,
                ),
                _Slide(
                  icon: Icons.verified_user_rounded,
                  title: 'Confiance et sécurité',
                  description:
                      'Chaque utilisateur est vérifié par téléphone. Vous choisissez librement avec qui partager votre trajet.',
                  gradient: [kOrange, const Color(0xFFFF6B00)],
                  page: 2,
                  total: 3,
                  onTap: _terminer,
                  onSkip: _terminer,
                ),
              ],
            ),
            if (_page < 2)
              Positioned(
                top: 12,
                right: 16,
                child: TextButton(
                  onPressed: _terminer,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade500,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Passer', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final int page;
  final int total;
  final VoidCallback onTap;
  final VoidCallback onSkip;
  final bool showLogo;

  const _Slide({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.page,
    required this.total,
    required this.onTap,
    required this.onSkip,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    // Gradient background circle or logo
                    if (showLogo)
                      Container(
                        width: size.width * 0.35,
                        height: size.width * 0.35,
                        constraints: const BoxConstraints(minWidth: 100, minHeight: 100),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kOrange.withAlpha(30),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo-officiel.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: size.width * 0.35,
                        height: size.width * 0.35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gradient[0].withAlpha(50),
                              blurRadius: 40,
                              spreadRadius: 5,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Icon(icon, size: 52, color: Colors.white),
                      ),
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: kTextSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(total, (i) {
                        final active = i == page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? kOrange : kBorder,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: onTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: kOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          page < 2 ? 'Suivant' : 'Commencer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
