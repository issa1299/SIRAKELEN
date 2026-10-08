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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kOrangeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_camera_rounded, color: kOrange),
              ),
              title: const Text('Prendre une photo',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kOrangeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: kOrange),
              ),
              title: const Text('Choisir dans la galerie',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await _picker.pickImage(
          source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (picked == null) return;
      setState(() => _photoFile = File(picked.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Photo inaccessible. Reessaie.'),
          backgroundColor: kRed));
    }
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
          content: Text('Profil mis à jour'), backgroundColor: kGreen));
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _erreur = e.toString().replaceFirst('Exception: ', '');
        _enregistrement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = ApiService.resolvePhoto(_photoUrl);
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Modifier mon profil')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          // Photo
                          Center(
                            child: GestureDetector(
                              onTap: _choisirPhoto,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 108,
                                    height: 108,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: kOrange.withAlpha(50),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _photoFile != null
                                          ? Image.file(_photoFile!,
                                              width: 108, height: 108, fit: BoxFit.cover)
                                          : (photo != null
                                              ? Image.network(photo,
                                                  width: 108,
                                                  height: 108,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      _avatarDefaut())
                                              : _avatarDefaut()),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: kOrange,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt_rounded,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text('Touche la photo pour la changer',
                                style: TextStyle(fontSize: 12, color: kTextSecondary)),
                          ),
                          const SizedBox(height: 24),
                          // Carte infos personnelles
                          _carteSection(
                            titre: 'INFOS PERSONNELLES',
                            enfants: [
                              _label('Prénom'),
                              TextFormField(
                                controller: _prenom,
                                style: const TextStyle(fontSize: 15),
                                decoration: const InputDecoration(
                                  hintText: 'Ex. Awa',
                                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Le prénom est obligatoire'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              _label('Nom'),
                              TextFormField(
                                controller: _nom,
                                style: const TextStyle(fontSize: 15),
                                decoration: const InputDecoration(
                                  hintText: 'Ex. Traoré',
                                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Le nom est obligatoire'
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _carteSection(
                            titre: 'LOCALISATION',
                            enfants: [
                              _label('Quartier principal'),
                              TextFormField(
                                controller: _quartier,
                                style: const TextStyle(fontSize: 15),
                                decoration: const InputDecoration(
                                  hintText: 'Ex. Kalaban Coro',
                                  prefixIcon:
                                      Icon(Icons.location_on_outlined, size: 20),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Le quartier est obligatoire'
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _carteSection(
                            titre: 'COMPTE',
                            enfants: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: kCream,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone_outlined,
                                        size: 20, color: kTextSecondary),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Numéro vérifié',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600)),
                                          SizedBox(height: 2),
                                          Text(
                                              'Lié à ton compte, non modifiable ici',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: kTextSecondary)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.verified_rounded,
                                        size: 18, color: kGreen),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_erreur != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: kRedLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kRed.withAlpha(50)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: kRed, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _erreur!,
                                      style: const TextStyle(
                                          color: kRed, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bouton fixe en bas
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed:
                            _enregistrement ? null : _enregistrer,
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
                  ),
                ),
              ],
            ),
    );
  }

  Widget _avatarDefaut() {
    return Container(
      color: kOrangeLight,
      child: const Icon(Icons.person_rounded, size: 52, color: kOrange),
    );
  }

  Widget _label(String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        texte,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: kTextSecondary),
      ),
    );
  }

  Widget _carteSection({required String titre, required List<Widget> enfants}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            titre,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: kTextSecondary),
          ),
          const SizedBox(height: 12),
          ...enfants,
        ],
      ),
    );
  }
}
