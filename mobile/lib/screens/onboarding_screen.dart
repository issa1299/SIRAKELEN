import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
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
      illustration: '1',
      eyebrow: 'VOYAGEZ MIEUX. DEPENSEZ MOINS.',
      title: 'Reduisez vos frais de transport au quotidien.',
      description:
          'Partagez les couts de deplacement avec des personnes qui effectuent un trajet similaire au votre.',
    ),
    _SlideData(
      illustration: '2',
      eyebrow: 'PUBLICATION SIMPLE. MATCHING INTELLIGENT.',
      title: 'Publiez votre trajet, nous trouvons les correspondances.',
      description:
          'Deposez un avis de deplacement en quelques secondes. Notre systeme identifie automatiquement les utilisateurs dont l\'itineraire est compatible avec le votre.',
    ),
    _SlideData(
      illustration: '3',
      eyebrow: 'SECURITE, CONFIANCE ET LIBERTE DE CHOIX.',
      title: 'Des trajets partages en toute confiance.',
      description:
          'Chaque utilisateur est verifie par numero de telephone. Vous choisissez librement les personnes avec lesquelles partager votre trajet.',
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
        _controller.animateToPage(nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic);
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
    _controller.animateToPage(_page + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic);
  }

  void _passer() {
    _autoScrollTimer?.cancel();
    _controller.animateToPage(_slides.length - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic);
  }

  void _creerCompte() {
    _autoScrollTimer?.cancel();
    SharedPreferences.getInstance()
        .then((p) => p.setBool('onboarding_vu', true));
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _seConnecter() {
    _autoScrollTimer?.cancel();
    SharedPreferences.getInstance()
        .then((p) => p.setBool('onboarding_vu', true));
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Barre de progression + compteur
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (_page + 1) / _slides.length,
                            minHeight: 6,
                            backgroundColor: kOrangeLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(kOrange),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_page + 1}/${_slides.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
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
                        isLast: isLast,
                        onSuivant: _suivant,
                        onCreerCompte: _creerCompte,
                        onSeConnecter: _seConnecter,
                      );
                    }),
                  ),
                ),
              ],
            ),
            if (_page < _slides.length - 1)
              Positioned(
                top: 12,
                right: 16,
                child: GestureDetector(
                  onTap: _passer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Passer',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600])),
                        if (_page == 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kOrangeLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('-40%',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: kOrange)),
                          ),
                        ],
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

class _SlideData {
  final String illustration;
  final String eyebrow;
  final String title;
  final String description;

  const _SlideData({
    required this.illustration,
    required this.eyebrow,
    required this.title,
    required this.description,
  });
}

class _Slide extends StatelessWidget {
  final _SlideData data;
  final int page;
  final int total;
  final bool isLast;
  final VoidCallback onSuivant;
  final VoidCallback onCreerCompte;
  final VoidCallback onSeConnecter;

  const _Slide({
    required this.data,
    required this.page,
    required this.total,
    required this.isLast,
    required this.onSuivant,
    required this.onCreerCompte,
    required this.onSeConnecter,
  });

  Widget _buildIllustration() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kOrangeLight,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kOrange.withAlpha(20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Image.asset(
              'assets/${data.illustration}.jpeg',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildIllustration(),
            const SizedBox(height: 36),
            Text(
              data.eyebrow,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: kOrange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.3,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 36),
            if (!isLast) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onSuivant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: kOrange.withAlpha(80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Suivant', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
            if (isLast) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onCreerCompte,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: kOrange.withAlpha(80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Creer un compte',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: onSeConnecter,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kTextPrimary,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'J\'ai deja un compte',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
