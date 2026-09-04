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
      appBar: AppBar(title: const Text('Vérification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Icon
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: kOrangeLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: kOrange,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Vérification du code',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.useEmail
                  ? 'Code envoyé à votre email'
                  : 'Code envoyé au',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kTextSecondary),
            ),
            Text(
              widget.useEmail ? widget.telephone : '+223 ${widget.telephone}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 32),

            // OTP digit boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Container(
                  width: 56,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
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
                        fontWeight: FontWeight.w800,
                        color: kTextPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: kBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: kBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
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

            const SizedBox(height: 12),

            // Timer
            Center(
              child: AnimatedBuilder(
                animation: _timerController,
                builder: (context, child) {
                  final remaining = (60 - (_timerController.value * 60)).ceil();
                  return Text(
                    _canResend ? 'Vous pouvez renvoyer le code' : 'Renvoyer le code dans ${remaining}s',
                    style: TextStyle(
                      fontSize: 13,
                      color: _canResend ? kOrange : kTextSecondary,
                      fontWeight: _canResend ? FontWeight.w600 : FontWeight.w400,
                    ),
                  );
                },
              ),
            ),

            if (_erreur != null) ...[
              const SizedBox(height: 16),
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
                onPressed: _chargement ? null : _confirmer,
                child: _chargement
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirmer'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _canResend && !_chargement ? _renvoyerCode : null,
                child: Text(
                  'Rien reçu ? Renvoyer le code',
                  style: TextStyle(
                    color: _canResend ? kOrange : Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
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
