/// Vérifie les mises à jour à l'entrée dans l'application (Android uniquement).
/// - Au démarrage à froid et à chaque retour au premier plan.
/// - Appelle /versions/latest?plateforme=android.
/// - Affiche UpdateDialog (« Télécharger » / « Plus tard ») si une version
///   plus récente est active, une seule fois par session pour la même version.
/// - Sur Web : la détection reste gérée par le service worker (index.html).
import 'package:flutter/material.dart';
import '../services/update_service.dart';
import 'update_dialog.dart';

class UpdateChecker extends StatefulWidget {
  final Widget child;
  const UpdateChecker({super.key, required this.child});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker>
    with WidgetsBindingObserver {
  String? _dejaProposee;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Différé d'une frame pour ne pas bloquer le premier rendu.
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifier());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // L'utilisateur revient dans l'app (depuis l'arrière-plan ou le navigateur).
    if (state == AppLifecycleState.resumed) _verifier();
  }

  Future<void> _verifier() async {
    if (_enCours || !mounted) return;
    _enCours = true;
    try {
      final version = await UpdateService.verifierDerniereVersion();
      if (!mounted || version == null) return;
      // Le Web continue d'utiliser la bannière du service worker.
      if (version.plateforme != 'android') return;
      if (!UpdateService.miseAJourDisponible(version)) return;
      // « Plus tard » vaut pour la session en cours : on ne réaffiche pas
      // la même boîte dès que l'utilisateur revient dans l'application.
      if (_dejaProposee == version.id) return;
      _dejaProposee = version.id;
      await UpdateDialog.show(context, version: version);
    } finally {
      _enCours = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
