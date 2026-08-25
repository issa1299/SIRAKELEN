import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class ContactUrgenceScreen extends StatefulWidget {
  final String userId;
  const ContactUrgenceScreen({super.key, required this.userId});

  @override
  State<ContactUrgenceScreen> createState() => _ContactUrgenceScreenState();
}

class _ContactUrgenceScreenState extends State<ContactUrgenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  final _lien = TextEditingController();
  bool _chargement = true;
  bool _enregistrement = false;
  String? _erreur;
  bool _existant = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _nom.dispose();
    _telephone.dispose();
    _lien.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final contact = await ApiService.getContactUrgence(widget.userId);
      if (contact != null) {
        _nom.text = contact['nomContact'] as String? ?? '';
        _telephone.text = contact['telephoneContact'] as String? ?? '';
        _lien.text = contact['lien'] as String? ?? '';
        _existant = true;
      }
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
      await ApiService.definirContactUrgence(
        userId: widget.userId,
        nomContact: _nom.text.trim(),
        telephoneContact: _telephone.text.trim(),
        lien: _lien.text.trim().isEmpty ? null : _lien.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Contact d’urgence enregistré'),
          backgroundColor: Color(0xFF1B7A2B)));
      Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() {
        _erreur = e.message;
        _enregistrement = false;
      });
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
          title: const Text('Contact d’urgence'),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F2E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'En cas d’accident ou d’imprévu sur la route, ton partenaire de trajet confirmé pourra joindre cette personne depuis l’app.',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF125A1E),
                            height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nom,
                      decoration: const InputDecoration(
                          labelText: 'Nom du contact',
                          hintText: 'Aïcha Diallo'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Le nom du contact est obligatoire'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _telephone,
                      keyboardType: TextInputType.phone,
                      maxLength: 8,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        prefixText: '+223  ',
                        counterText: '',
                        hintText: '70 98 76 54',
                      ),
                      validator: (v) {
                        final c = v?.replaceAll(' ', '') ?? '';
                        if (c.length != 8) {
                          return '8 chiffres obligatoires';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _lien,
                      decoration: const InputDecoration(
                          labelText: 'Lien (facultatif)',
                          hintText: 'Sœur, frère, parent…'),
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
                          : Text(_existant
                              ? 'Mettre à jour'
                              : 'Ajouter maintenant'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
