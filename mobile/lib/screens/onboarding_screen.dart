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
  static const _autoScrollDuration = Duration(seconds: 8);

  final _slides = const [
    _SlideData(
      image: 'assets/1.jpeg',
      eyebrow: 'VOYAGEZ MIEUX. DÉPENSEZ MOINS.',
      title: 'Réduisez vos frais de transport au quotidien.',
      description:
          'Partagez les coûts de déplacement avec des personnes qui effectuent un trajet similaire au vôtre.',
    ),
    _SlideData(
      image: 'assets/2.jpeg',
      eyebrow: 'PUBLICATION SIMPLE. MATCHING INTELLIGENT.',
      title: 'Publiez votre trajet, nous trouvons les correspondances.',
      description:
          'Déposez un avis de déplacement en quelques secondes. Notre système identifie automatiquement les utilisateurs dont l\'itinéraire est compatible avec le vôtre.',
    ),
    _SlideData(
      image: 'assets/3.jpeg',
      eyebrow: 'SÉCURITÉ, CONFIANCE ET LIBERTÉ DE CHOIX.',
      title: 'Des trajets partagés en toute confiance.',
      description:
          'Chaque utilisateur est vérifié. Vous choisissez librement les personnes avec lesquelles partager votre trajet.',
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

  void _passer() {
    _autoScrollTimer?.cancel();
    _controller.animateToPage(_slides.length - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic);
  }

  void _suivant() {
    _autoScrollTimer?.cancel();
    _controller.animateToPage(_page + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic);
  }

  Future<void> _marquerVu() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_vu', true);
  }

  void _creerCompte() {
    _autoScrollTimer?.cancel();
    _marquerVu();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  void _seConnecter() {
    _autoScrollTimer?.cancel();
    _marquerVu();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
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
                isLast: isLast,
                onSuivant: _suivant,
                onCreerCompte: _creerCompte,
                onSeConnecter: _seConnecter,
              );
            }),
          ),
          // Haut : progression + compteur + Passer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (_page + 1) / _slides.length,
                        minHeight: 5,
                        backgroundColor: Colors.white.withAlpha(70),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_page + 1}/${_slides.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_page < _slides.length - 1)
                    GestureDetector(
                      onTap: _passer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Passer',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final String image;
  final String eyebrow;
  final String title;
  final String description;

  const _SlideData({
    required this.image,
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image plein écran
        Image.asset(data.image, fit: BoxFit.cover),
        // Voile sombre pour lire le texte
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(70),
                Colors.black.withAlpha(30),
                Colors.black.withAlpha(190),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        // Contenu bas
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  data.eyebrow,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Color(0xFFFFB25E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withAlpha(220),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(total, (i) {
                    final active = i == page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      margin: const EdgeInsets.only(right: 6),
                      width: active ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white.withAlpha(90),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                if (!isLast)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onSuivant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Suivant',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onCreerCompte,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Créer un compte',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: onSeConnecter,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'J\'ai déjà un compte',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
