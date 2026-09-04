import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'welcome_screen.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  Timer? _autoScrollTimer;

  static const _autoScrollDuration = Duration(seconds: 5);

  final _slides = const [
    _SlideData(
      icon: Icons.savings_rounded,
      key: 'Voyagez mieux. Dépensez moins.',
      title: 'Réduisez vos frais de transport',
      description:
          'Partagez les coûts de déplacement avec des personnes qui effectuent un trajet similaire au vôtre.',
      gradient: [kOrange, Color(0xFFFF9A3E)],
      showLogo: true,
    ),
    _SlideData(
      icon: Icons.auto_awesome_rounded,
      key: 'Publication simple. Matching intelligent.',
      title: 'Matching intelligent',
      description:
          'Publiez votre trajet en quelques secondes. Le système identifie automatiquement les utilisateurs compatibles.',
      gradient: [Color(0xFFE25F00), kOrange],
    ),
    _SlideData(
      icon: Icons.verified_user_rounded,
      key: 'Sécurité, confiance et liberté de choix.',
      title: 'Confiance et sécurité',
      description:
          'Chaque utilisateur est vérifié par téléphone. Vous choisissez librement les personnes avec lesquelles partager votre trajet.',
      gradient: [kOrange, Color(0xFFFF6B00)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(_autoScrollDuration, (_) {
      if (!mounted) return;
      final nextPage = _page + 1;
      if (nextPage < _slides.length) {
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _autoScrollTimer?.cancel();
      }
    });
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    if (i < _slides.length - 1) {
      _startAutoScroll();
    } else {
      _autoScrollTimer?.cancel();
    }
  }

  void _suivant() {
    _autoScrollTimer?.cancel();
    _controller.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _terminer() async {
    _autoScrollTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_vu', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  void _creerCompte() {
    _autoScrollTimer?.cancel();
    final prefs = SharedPreferences.getInstance();
    prefs.then((p) => p.setBool('onboarding_vu', true));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _seConnecter() {
    _autoScrollTimer?.cancel();
    final prefs = SharedPreferences.getInstance();
    prefs.then((p) => p.setBool('onboarding_vu', true));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: List.generate(_slides.length, (i) {
                final s = _slides[i];
                final isLast = i == _slides.length - 1;
                return _Slide(
                  data: s,
                  page: i,
                  total: _slides.length,
                  onTap: isLast ? null : _suivant,
                  onSkip: _terminer,
                  isLast: isLast,
                  onCreerCompte: _creerCompte,
                  onSeConnecter: _seConnecter,
                );
              }),
            ),
            if (_page < _slides.length - 1)
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

class _SlideData {
  final IconData icon;
  final String key;
  final String title;
  final String description;
  final List<Color> gradient;
  final bool showLogo;

  const _SlideData({
    required this.icon,
    required this.key,
    required this.title,
    required this.description,
    required this.gradient,
    this.showLogo = false,
  });
}

class _Slide extends StatelessWidget {
  final _SlideData data;
  final int page;
  final int total;
  final VoidCallback? onTap;
  final VoidCallback onSkip;
  final bool isLast;
  final VoidCallback onCreerCompte;
  final VoidCallback onSeConnecter;

  const _Slide({
    required this.data,
    required this.page,
    required this.total,
    required this.onTap,
    required this.onSkip,
    required this.isLast,
    required this.onCreerCompte,
    required this.onSeConnecter,
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
                    if (data.showLogo)
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
                            colors: data.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: data.gradient[0].withAlpha(50),
                              blurRadius: 40,
                              spreadRadius: 5,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Icon(data.icon, size: 52, color: Colors.white),
                      ),
                    const SizedBox(height: 24),
                    // Key label
                    Text(
                      data.key.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: kOrange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Title
                    Text(
                      data.title,
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
                        data.description,
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
                    if (isLast) ...[
                      // Last slide: two CTAs
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: onCreerCompte,
                          style: FilledButton.styleFrom(
                            backgroundColor: kOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Créer un compte',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: onSeConnecter,
                        child: Text.rich(
                          TextSpan(
                            text: 'J\'ai déjà un compte',
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
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
                          child: const Text(
                            'Suivant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
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
