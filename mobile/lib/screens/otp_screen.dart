import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'contact_urgence_screen.dart';

class OtpScreen extends StatefulWidget {
  final String telephone;
  final String userId;
  final String prenom;
  const OtpScreen({
    super.key,
    required this.telephone,
    required this.userId,
    this.prenom = '',
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  String? _erreur;
  bool _chargement = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
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
      // Le backend vérifie le code reçu par SMS.
      await ApiService.verifierCodeOtp(widget.telephone, code);
      await ApiService.marquerVerifie(widget.userId);
      if (!mounted) return;
      // Invitation au contact d'urgence (non bloquante), puis accueil.
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
              'Code valable 5 minutes',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 14),
              Text(
                _erreur!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFFA3392F),
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
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
              onPressed: _chargement ? null : _renvoyerCode,
              child: const Text('Rien reçu ? Renvoyer le code'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renvoyerCode() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await ApiService.envoyerCodeOtp(widget.telephone);
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = null;
      });
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
}
