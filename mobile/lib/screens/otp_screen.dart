import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'contact_urgence_screen.dart';
import 'code_recuperation_screen.dart';

class OtpScreen extends StatefulWidget {
  final String telephone;
  final String userId;
  final String prenom;
  final bool useEmail;
  final bool isCodeOublie;

  const OtpScreen({
    super.key,
    required this.telephone,
    required this.userId,
    this.prenom = '',
    this.useEmail = false,
    this.isCodeOublie = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  String? _erreur;
  bool _chargement = false;
  bool _canResend = false;
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _canResend = true);
        }
      });
    _startTimer();
    _envoyerLeCode();
  }

  void _startTimer() {
    _canResend = false;
    _timerController.forward(from: 0);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _envoyerLeCode() async {
    try {
      if (widget.useEmail) {
        await ApiService.envoyerCodeOtpEmail(widget.telephone);
      } else {
        await ApiService.envoyerCodeOtp(widget.telephone);
      }
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } catch (e) {
      setState(() => _erreur = 'Connexion au serveur impossible');
    }
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _confirmer() async {
    final code = _code;
    if (code.length != 4) {
      setState(() => _erreur = 'Le code contient 4 chiffres');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      if (widget.useEmail) {
        await ApiService.verifierCodeOtpEmail(widget.telephone, code);
      } else {
        await ApiService.verifierCodeOtp(widget.telephone, code);
      }
      if (widget.isCodeOublie) {
        // Code oublié flow: after SMS verification, go to recovery code creation
        final user = await ApiService.findByTelephone(widget.telephone);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => CodeRecuperationScreen(
              telephone: widget.telephone,
              userId: user?['id'] as String? ?? '',
              prenom: user?['prenom'] as String? ?? '',
            ),
          ),
          (route) => false,
        );
      } else if (widget.userId.isEmpty) {
        // New registration: after SMS verification, go to recovery code creation
        final user = await ApiService.findByTelephone(widget.telephone);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => CodeRecuperationScreen(
              telephone: widget.telephone,
              userId: user?['id'] as String? ?? '',
              prenom: user?['prenom'] as String? ?? '',
            ),
          ),
          (route) => false,
        );
      } else {
        await ApiService.marquerVerifie(widget.userId);
        await Session.sauver(widget.userId, widget.prenom);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ContactUrgenceScreen(
              userId: widget.userId,
              invitation: true,
            ),
          ),
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur = 'Connexion au serveur impossible';
        _chargement = false;
      });
    }
  }

  Future<void> _renvoyerCode() async {
    if (!_canResend) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      if (widget.useEmail) {
        await ApiService.envoyerCodeOtpEmail(widget.telephone);
      } else {
        await ApiService.envoyerCodeOtp(widget.telephone);
      }
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = null;
      });
      _startTimer();
    } on ApiException catch (e) {
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
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
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero orange
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 64,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kOrange, kOrangeDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: kTextPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Vérifie ton code',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.useEmail
                          ? 'Code envoyé à ${widget.telephone}'
                          : 'Code envoyé au +223 ${widget.telephone}',
                      style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.5),
                    ),
                  ],
                ),
              ),
              // Carte code chevauchante
              Transform.translate(
                offset: const Offset(0, -40),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cases OTP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (i) {
                          return SizedBox(
                            width: 62,
                            height: 64,
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey == LogicalKeyboardKey.backspace &&
                                    _controllers[i].text.isEmpty &&
                                    i > 0) {
                                  _controllers[i - 1].clear();
                                  _focusNodes[i - 1].requestFocus();
                                }
                              },
                              child: TextField(
                                controller: _controllers[i],
                                focusNode: _focusNodes[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: kTextPrimary,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: const Color(0xFFF4F2EC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: kOrange, width: 2),
                                  ),
                                ),
                                onChanged: (v) {
                                  if (v.isNotEmpty && i < 3) {
                                    _focusNodes[i + 1].requestFocus();
                                  }
                                  if (_code.length == 4) _confirmer();
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      // Timer / renvoyer
                      Center(
                        child: AnimatedBuilder(
                          animation: _timerController,
                          builder: (context, child) {
                            final remaining = (60 - (_timerController.value * 60)).ceil();
                            return _canResend
                                ? GestureDetector(
                                    onTap: _chargement ? null : _renvoyerCode,
                                    child: const Text(
                                      'Pas reçu ? Renvoyer le code',
                                      style: TextStyle(fontSize: 13, color: kOrange, fontWeight: FontWeight.w700),
                                    ),
                                  )
                                : Text(
                                    'Renvoyer le code dans ${remaining}s',
                                    style: TextStyle(fontSize: 13, color: kTextSecondary),
                                  );
                          },
                        ),
                      ),
                      if (_erreur != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kRedLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: kRed, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _erreur!,
                                  style: const TextStyle(color: kRed, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _chargement ? null : _confirmer,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                          ),
                          child: _chargement
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text('Vérifier', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
