/// Fenêtre de mise à jour (Android).
/// Présente la nouvelle version, la date, les nouveautés et la taille.
/// - Bouton Télécharger : ouvre l'URL de l'APK Release dans le navigateur.
/// - Bouton Plus tard : uniquement si la mise à jour est facultative.
/// - Si obligatoire : la fenêtre ne peut pas être fermée (barrierDismissible: false).
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final AppVersionInfo version;
  final VoidCallback? onPlusTard;

  const UpdateDialog({super.key, required this.version, this.onPlusTard});

  /// Affiche la fenêtre. Retourne true si l'utilisateur a choisi de télécharger.
  static Future<bool?> show(
    BuildContext context, {
    required AppVersionInfo version,
    VoidCallback? onPlusTard,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !version.obligatoire,
      builder: (_) => UpdateDialog(version: version, onPlusTard: onPlusTard),
    );
  }

  Future<void> _telecharger() async {
    final url = version.apkUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime d) {
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${d.day} ${mois[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final nouveautes = version.notes
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kOrangeLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.system_update_rounded, color: kOrange, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Mise à jour disponible',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Version ${version.version} · ${_formatDate(version.datePublication)}',
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: kOrange,
              ),
            ),
            if (version.obligatoire) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: kRedLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Mise à jour obligatoire',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kRed),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Nouveautés',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...nouveautes.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_rounded, size: 16, color: kGreen),
                    const SizedBox(width: 6),
                    Expanded(child: Text(n, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ),
            if (version.tailleLisible.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Taille : ${version.tailleLisible}',
                style: const TextStyle(fontSize: 12, color: kTextSecondary),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!version.obligatoire)
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              onPlusTard?.call();
            },
            child: const Text('Plus tard'),
          ),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context, true);
            _telecharger();
          },
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Télécharger'),
        ),
      ],
    );
  }
}
