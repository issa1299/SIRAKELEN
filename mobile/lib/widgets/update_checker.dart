/// Vérifie les mises à jour au démarrage (Android uniquement).
/// - Appelle /versions/latest?plateforme=android.
/// - Affiche UpdateDialog si une version plus récente est active.
/// - Sur Web : la détection est gérée par le service worker dans index.html.
import 'package:flutter/material.dart';
import '../services/update_service.dart';
import 'update_dialog.dart';

class UpdateChecker extends StatefulWidget {
  final Widget child;
  const UpdateChecker({super.key, required this.child});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  @override
  void initState() {
    super.initState();
    // Différé pour ne pas bloquer le premier rendu.
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifier());
  }

  Future<void> _verifier() async {
    // Le web gère ses mises à jour via service worker (bannière index.html).
    // Ici on cible Android uniquement via la plateforme envoyée par le service.
    final version = await UpdateService.verifierDerniereVersion();
    if (version == null || !mounted) return;
    if (!UpdateService.miseAJourDisponible(version)) return;
    if (version.plateforme != 'android') return;

    await UpdateDialog.show(context, version: version);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
