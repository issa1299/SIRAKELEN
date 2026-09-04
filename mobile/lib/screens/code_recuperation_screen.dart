import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'main_scaffold.dart';

class CodeRecuperationScreen extends StatefulWidget {
  final String telephone;
  final String userId;
  final String prenom;

  const CodeRecuperationScreen({
    super.key,
    required this.telephone,
    required this.userId,
    required this.prenom,
  });

  @override
  State<CodeRecuperationScreen> createState() => _CodeRecuperationScreenState();
}

class _CodeRecuperationScreenState extends State<CodeRecuperationScreen> {
  final _codeControllers = List.generate(4, (_) => TextEditingController());
  final _confirmControllers = List.generate(4, (_) => TextEditingController());
  final _codeFocusNodes = List.generate(4, (_) => FocusNode());
  final _confirmFocusNodes = List.generate(4, (_) => FocusNode());
  String? _erreur;
  bool _chargement = false;

  @override
  void dispose() {
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final c in _confirmControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    for (final f in _confirmFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _codeControllers.map((c) => c.text).join();
  String get _confirm => _confirmControllers.map((c) => c.text).join();

  Future<void> _continuer() async {
    if (_code.length != 4) {
      setState(() => _erreur = 'Saisis un code à 4 chiffres');
      return;
    }
    if (_code != _confirm) {
      setState(() => _erreur = 'Les codes ne correspondent pas');
      return;
    }
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await ApiService.definirCodeRecuperation(widget.telephone, _code);
      if (!mounted) return;
      await Session.sauver(widget.userId, widget.prenom);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainScaffold(
            userId: widget.userId,
            prenom: widget.prenom,
          ),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    } catch (_) {
      setState(() {
        _erreur = 'Erreur lors de l\'enregistrement';
        _chargement = false;
      });
    }
  }

  Widget _buildOtpRow({
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    bool isConfirm = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        return Container(
          width: 56,
          height: 62,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: TextField(
            controller: controllers[i],
            focusNode: focusNodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            obscureText: true,
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
              fillColor: controllers[i].text.isNotEmpty ? kOrangeLight : Colors.white,
            ),
            onChanged: (val) {
              setState(() {});
              if (val.isNotEmpty && i < 3) {
                final nextNodes = isConfirm ? _confirmFocusNodes : _codeFocusNodes;
                nextNodes[i + 1].requestFocus();
              }
              if (val.isEmpty && i > 0) {
                final prevNodes = isConfirm ? _confirmFocusNodes : _codeFocusNodes;
                prevNodes[i - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Code de récupération')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Créez votre code de récupération',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ce code vous permettra de récupérer votre compte sur un autre appareil. Conservez-le précieusement.',
              style: TextStyle(fontSize: 14, color: kTextSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),
            const Text(
              'Code à 4 chiffres',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextSecondary),
            ),
            const SizedBox(height: 10),
            _buildOtpRow(
              controllers: _codeControllers,
              focusNodes: _codeFocusNodes,
            ),
            const SizedBox(height: 24),
            const Text(
              'Confirmez le code',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTextSecondary),
            ),
            const SizedBox(height: 10),
            _buildOtpRow(
              controllers: _confirmControllers,
              focusNodes: _confirmFocusNodes,
              isConfirm: true,
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
                        style: const TextStyle(color: kRed, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
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
          ],
        ),
      ),
    );
  }
}
