import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_scaffold.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _telephone = TextEditingController();
  String? _erreur;
  bool _chargement = false;

  @override
  void dispose() {
    _telephone.dispose();
    super.dispose();
  }

  Future<void> _continuer() async {
    final chiffres = _telephone.text.replaceAll(' ', '');
    if (chiffres.length != 8) {
      setState(() => _erreur = 'Le numéro doit contenir 8 chiffres');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      // TODO Phase 2 : vérifier le compte par code SMS (Firebase) ici.
      final user = await ApiService.findByTelephone(chiffres);
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _erreur = 'Aucun compte avec ce numéro. Crée un compte d’abord.';
          _chargement = false;
        });
        return;
      }
      await Session.sauver(
          user['id'] as String? ?? '', user['prenom'] as String? ?? '');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScaffold(
            userId: user['id'] as String? ?? '',
            prenom: user['prenom'] as String? ?? '',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _erreur = 'Connexion au serveur impossible';
        _detailErreur = e.toString();
        _chargement = false;
      });
    }
  }

  String? _detailErreur;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion'), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text('Bon retour ! 👋',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'Entrez votre numéro pour recevoir un code de connexion.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _telephone,
              keyboardType: TextInputType.phone,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                prefixText: '+223  ',
                counterText: '',
                hintText: '70 12 34 56',
              ),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 14),
              Text(_erreur!,
                  style: const TextStyle(
                      color: Color(0xFFA3392F),
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              if (_detailErreur != null)
                Text(_detailErreur!,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 10)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _chargement ? null : _continuer,
              child: _chargement
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }
}
