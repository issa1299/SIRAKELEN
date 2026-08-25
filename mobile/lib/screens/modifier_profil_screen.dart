import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class ModifierProfilScreen extends StatefulWidget {
  final String userId;
  const ModifierProfilScreen({super.key, required this.userId});

  @override
  State<ModifierProfilScreen> createState() => _ModifierProfilScreenState();
}

class _ModifierProfilScreenState extends State<ModifierProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _quartier = TextEditingController();
  bool _chargement = true;
  bool _enregistrement = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    _quartier.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final user = await ApiService.getUser(widget.userId);
      _prenom.text = user['prenom'] as String? ?? '';
      _nom.text = user['nom'] as String? ?? '';
      _quartier.text = user['quartier'] as String? ?? '';
      if (!mounted) return;
      setState(() => _chargement = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enregistrement = true;
      _erreur = null;
    });
    try {
      await ApiService.updateProfil(
        widget.userId,
        prenom: _prenom.text.trim(),
        nom: _nom.text.trim(),
        quartier: _quartier.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profil mis à jour'),
          backgroundColor: Color(0xFF1B7A2B)));
      Navigator.pop(context);
    } catch (_) {
      setState(() {
        _erreur = 'Enregistrement impossible';
        _enregistrement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Modifier mon profil'),
          backgroundColor: Colors.transparent),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _prenom,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Le prénom est obligatoire'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nom,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Le nom est obligatoire'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _quartier,
                      decoration: const InputDecoration(
                          labelText: 'Quartier principal',
                          prefixIcon: Icon(Icons.location_on_outlined)),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Le quartier est obligatoire'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        helperText:
                            'Le numéro ne peut pas être modifié ici (vérification SMS requise)',
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text('Vérifié',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    if (_erreur != null) ...[
                      const SizedBox(height: 14),
                      Text(_erreur!,
                          style: const TextStyle(
                              color: Color(0xFFA3392F), fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _enregistrement ? null : _enregistrer,
                      child: _enregistrement
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : const Text('Enregistrer'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
