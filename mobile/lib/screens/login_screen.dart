import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'main_scaffold.dart';
import 'register_screen.dart';
import 'code_oublie_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _codeControllers = List.generate(4, (_) => TextEditingController());
  final _codeFocusNodes = List.generate(4, (_) => FocusNode());
  int _etape = 1;
  String? _erreur;
  bool _chargement = false;
  String _telephone = '';

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _continuer() async {
    final text = _phoneController.text.trim().replaceAll(' ', '');
    if (text.length != 8 || !RegExp(r'^[0-9]{8}$').hasMatch(text)) {
      setState(() => _erreur = 'Numéro de téléphone invalide (8 chiffres)');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final user = await ApiService.findByTelephone(text);
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _erreur = 'Aucun compte avec ce numéro. Crée un compte d\'abord.';
          _chargement = false;
        });
        return;
      }
      setState(() {
        _telephone = text;
        _etape = 2;
        _chargement = false;
        _erreur = null;
      });
      // Focus first code field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _codeFocusNodes[0].requestFocus();
      });
    } catch (_) {
      setState(() {
        _erreur = 'Connexion au serveur impossible';
        _chargement = false;
      });
    }
  }

  Future<void> _verifierCode() async {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length != 4) {
      setState(() => _erreur = 'Le code doit contenir 4 chiffres');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final result = await ApiService.verifierCodeRecuperation(_telephone, code);
      if (!mounted) return;
      await Session.sauver(
        result['id'] as String? ?? '',
        result['prenom'] as String? ?? '',
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScaffold(
            userId: result['id'] as String? ?? '',
            prenom: result['prenom'] as String? ?? '',
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    } catch (_) {
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
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            if (_etape == 1) ..._buildEtape1() else ..._buildEtape2(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEtape1() {
    return [
      const Text(
        'Bon retour !',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: kTextPrimary,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Saisissez votre numéro pour accéder à votre compte.',
        style: TextStyle(fontSize: 14, color: kTextSecondary),
      ),
      const SizedBox(height: 28),
      const Text(
        'Numéro de téléphone',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextSecondary),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Container(
            width: 72,
            height: 52,
            decoration: BoxDecoration(
              color: kGreyLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            alignment: Alignment.center,
            child: const Text(
              '+223',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                hintText: '70 12 34 56',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
              onSubmitted: (_) => _continuer(),
            ),
          ),
        ],
      ),
      if (_erreur != null) ...[
        const SizedBox(height: 14),
        _buildErreur(),
      ],
      const Spacer(),
      SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: _chargement ? null : _continuer,
          child: _chargement
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : const Text('Continuer'),
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: TextButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: Text.rich(
            TextSpan(
              text: 'Nouveau ici ? ',
              style: TextStyle(color: kTextSecondary, fontSize: 14),
              children: [
                TextSpan(
                  text: 'Créer mon compte',
                  style: TextStyle(color: kOrange, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildEtape2() {
    return [
      Text(
        'Ce numéro est déjà associé à un compte.',
        style: TextStyle(fontSize: 13, color: kTextSecondary),
      ),
      const SizedBox(height: 6),
      const Text(
        'Entrez votre code de récupération pour continuer',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: kTextPrimary,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '+223 $_telephone',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: kTextPrimary,
        ),
      ),
      const SizedBox(height: 28),
      // OTP boxes
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          return Container(
            width: 56,
            height: 62,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: TextField(
              controller: _codeControllers[i],
              focusNode: _codeFocusNodes[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorder, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kOrange, width: 2),
                ),
                filled: true,
                fillColor: _codeControllers[i].text.isNotEmpty ? kOrangeLight : Colors.white,
              ),
              onChanged: (val) {
                setState(() {});
                if (val.isNotEmpty && i < 3) {
                  _codeFocusNodes[i + 1].requestFocus();
                }
                if (val.isEmpty && i > 0) {
                  _codeFocusNodes[i - 1].requestFocus();
                }
              },
            ),
          );
        }),
      ),
      if (_erreur != null) ...[
        const SizedBox(height: 14),
        _buildErreur(),
      ],
      const Spacer(),
      SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: _chargement ? null : _verifierCode,
          child: _chargement
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : const Text('Continuer'),
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CodeOublieScreen()),
            );
          },
          child: Text(
            'Code oublié ?',
            style: TextStyle(
              color: kOrange,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildErreur() {
    return Container(
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
    );
  }
}
