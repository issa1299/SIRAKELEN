import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'main_scaffold.dart';

class ContactUrgenceScreen extends StatefulWidget {
  final String userId;
  final bool invitation;
  const ContactUrgenceScreen({
    super.key,
    required this.userId,
    this.invitation = false,
  });

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
      if (widget.invitation) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainScaffold(userId: widget.userId)),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Contact d\'urgence enregistré'),
            backgroundColor: kGreen));
        Navigator.pop(context);
      }
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
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Contact d\'urgence')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    // Safety info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kGreenLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: kGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'En cas d\'accident ou d\'imprévu, ton partenaire pourra joindre cette personne depuis l\'app.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF125A1E),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nom,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'Nom du contact',
                        hintText: 'Aïcha Diallo',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Le nom du contact est obligatoire'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telephone,
                      keyboardType: TextInputType.phone,
                      maxLength: 8,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        prefixText: '+223  ',
                        counterText: '',
                        hintText: '70 98 76 54',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: (v) {
                        final c = v?.replaceAll(' ', '') ?? '';
                        if (c.length != 8) {
                          return '8 chiffres obligatoires';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lien,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'Lien (facultatif)',
                        hintText: 'Sœur, frère, parent…',
                        prefixIcon: Icon(Icons.family_restroom_rounded, size: 20),
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
                                style: const TextStyle(color: kRed, fontSize: 13),
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
                        onPressed: _enregistrement ? null : _enregistrer,
                        child: _enregistrement
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_existant ? 'Mettre à jour' : 'Ajouter maintenant'),
                      ),
                    ),
                    if (widget.invitation) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => MainScaffold(userId: widget.userId)),
                              (route) => false,
                            );
                          },
                          child: Text(
                            'Plus tard',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kTextSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
