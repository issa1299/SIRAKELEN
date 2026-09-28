import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _photoUrl;
  File? _photoFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _charger();
    // Si Android a tue l'app pendant la prise de photo, recupere le fichier.
    if (Platform.isAndroid) _recupererPhotoPerdue();
  }

  Future<void> _recupererPhotoPerdue() async {
    try {
      final reponse = await _picker.retrieveLostData();
      if (reponse.file != null) {
        if (!mounted) return;
        setState(() => _photoFile = File(reponse.file!.path));
      }
    } catch (_) {}
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
      _photoUrl = user['photoUrl'] as String?;
      if (!mounted) return;
      setState(() => _chargement = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _choisirPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked == null) return;
    setState(() => _photoFile = File(picked.path));
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enregistrement = true;
      _erreur = null;
    });
    try {
      String? newPhotoUrl = _photoUrl;
      if (_photoFile != null) {
        newPhotoUrl = await ApiService.uploadPhoto(widget.userId, _photoFile!);
      }
      await ApiService.updateProfil(
        widget.userId,
        prenom: _prenom.text.trim(),
        nom: _nom.text.trim(),
        quartier: _quartier.text.trim(),
        photoUrl: newPhotoUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profil mis à jour'),
          backgroundColor: kGreen));
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _erreur = 'Erreur : ${e.toString()}';
        _enregistrement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Modifier mon profil')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Photo de profil
                    Center(
                      child: GestureDetector(
                        onTap: _choisirPhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: kOrangeLight,
                              backgroundImage: _photoFile != null
                                  ? FileImage(_photoFile!)
                                  : (_photoUrl != null && _photoUrl!.isNotEmpty
                                      ? NetworkImage('${ApiService.baseUrl}$_photoUrl') as ImageProvider
                                      : null),
                              child: (_photoFile == null && (_photoUrl == null || _photoUrl!.isEmpty))
                                  ? const Icon(Icons.person_rounded, size: 50, color: kOrange)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: kOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text('Appuyez pour changer la photo', style: TextStyle(fontSize: 12, color: kTextSecondary)),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _prenom,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Le prénom est obligatoire'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nom,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Le nom est obligatoire'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quartier,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'Quartier principal',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Le quartier est obligatoire'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Numéro de téléphone',
                        helperText: 'Vérification SMS requise pour modifier',
                        helperStyle: TextStyle(color: kTextSecondary, fontSize: 12),
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 14, color: kGreen),
                          const SizedBox(width: 6),
                          Text(
                            'Vérifié',
                            style: TextStyle(fontSize: 13, color: kTextSecondary),
                          ),
                        ],
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
                            : const Text('Enregistrer'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
