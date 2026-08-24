import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String telephone;
  final String userId;
  const OtpScreen({super.key, required this.telephone, required this.userId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  final _auth = AuthService();
  String? _verificationId;
  String? _erreur;
  bool _chargement = false;
  bool _codeEnvoye = false;

  @override
  void initState() {
    super.initState();
    _envoyerCode();
  }

  Future<void> _envoyerCode() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    if (!AuthService.firebaseDisponible) {
      // Mode dev : Firebase pas encore configuré (google-services.json absent).
      setState(() {
        _codeEnvoye = true;
        _chargement = false;
        _verificationId = null;
      });
      return;
    }
    try {
      await _auth.envoyerCode(
        telephone: widget.telephone,
        codeEnvoye: (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _codeEnvoye = true;
            _chargement = false;
          });
        },
        erreur: (message) {
          setState(() {
            _erreur = message;
            _chargement = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _erreur = 'Envoi du code impossible';
        _chargement = false;
      });
    }
  }

  Future<void> _confirmer() async {
    final code = _code.text.trim();
    if (code.length != 4) {
      setState(() => _erreur = 'Le code contient 4 chiffres');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      if (AuthService.firebaseDisponible && _verificationId != null) {
        // Vérification réelle via Firebase.
        await _auth.verifierCode(
          verificationId: _verificationId!,
          code: code,
        );
      } else {
        // Mode dev : simulation.
        await Future.delayed(const Duration(milliseconds: 600));
      }
      await ApiService.marquerVerifie(widget.userId);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    } catch (e) {
      setState(() {
        _erreur = 'Code incorrect ou expiré';
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification'), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text(
              'Code envoyé au',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            Text(
              '+223 ${widget.telephone}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            if (!AuthService.firebaseDisponible) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Mode dev : Firebase non configuré — entrez 4 chiffres au choix.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Color(0xFFB35A00)),
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 12),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '••••',
              ),
              onChanged: (v) {
                if (v.length == 4) _confirmer();
              },
            ),
            const SizedBox(height: 10),
            Text(
              _codeEnvoye ? 'Code valide encore 02:30' : 'Envoi du code…',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 14),
              Text(
                _erreur!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFA3392F), fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _chargement ? null : _confirmer,
              child: _chargement
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Confirmer'),
            ),
            TextButton(
              onPressed: _chargement ? null : _envoyerCode,
              child: const Text('Rien reçu ? Renvoyer le code'),
            ),
          ],
        ),
      ),
    );
  }
}
