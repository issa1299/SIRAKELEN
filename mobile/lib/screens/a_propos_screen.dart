/// Écran « À propos de SiraKelen » avec rubrique Mises à jour.
/// Affiche la version installée, la dernière version, la date de publication,
/// l'historique des nouveautés et un bouton « Vérifier les mises à jour ».
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/update_service.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/update_dialog.dart';

class AProposScreen extends StatefulWidget {
  const AProposScreen({super.key});

  @override
  State<AProposScreen> createState() => _AProposScreenState();
}

class _AProposScreenState extends State<AProposScreen> {
  AppVersionInfo? _derniere;
  bool _verification = false;

  @override
  void initState() {
    super.initState();
    _verifier(afficherDialog: false);
  }

  Future<void> _verifier({bool afficherDialog = true}) async {
    setState(() => _verification = true);
    final version = await UpdateService.verifierDerniereVersion();
    if (!mounted) return;
    setState(() {
      _derniere = version;
      _verification = false;
    });
    if (afficherDialog && version != null) {
      if (UpdateService.miseAJourDisponible(version)) {
        await UpdateDialog.show(context, version: version);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez la dernière version.'),
            backgroundColor: kGreen,
          ),
        );
      }
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
    final aMiseAJour =
        _derniere != null && UpdateService.miseAJourDisponible(_derniere);

    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('À propos de SiraKelen')),
      body: ResponsiveWrapper(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Logo + présentation
            Center(
              child: Column(
                children: [
                  Image.asset('assets/logo-officiel.png', width: 80, height: 80),
                  const SizedBox(height: 12),
                  const Text(
                    'SIRA KELEN',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kOrange),
                  ),
                  const Text(
                    'Partagez la route. Partagez le coût.',
                    style: TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Version installée
            _infoCard(
              title: 'Version installée',
              icon: Icons.info_outline_rounded,
              rows: [
                ['Version', UpdateService.versionInstallee],
                ['Code de version', '${UpdateService.buildInstalle}'],
                ['Plateforme', 'Android'],
              ],
            ),
            const SizedBox(height: 16),

            // Dernière version
            _infoCard(
              title: 'Dernière version disponible',
              icon: Icons.system_update_rounded,
              rows: _derniere == null
                  ? [['Statut', 'Non vérifiée']]
                  : [
                      ['Version', _derniere!.version],
                      ['Date de publication', _formatDate(_derniere!.datePublication)],
                      ['Mise à jour', aMiseAJour ? 'Disponible' : 'À jour'],
                      if (_derniere!.obligatoire)
                        ['Type', 'Obligatoire'],
                      if (_derniere!.tailleLisible.isNotEmpty)
                        ['Taille', _derniere!.tailleLisible],
                    ],
            ),
            const SizedBox(height: 16),

            // Historique des nouveautés
            if (_derniere != null && _derniere!.notes.isNotEmpty) ...[
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nouveautés de la version ${_derniere!.version}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    ..._derniere!.notes
                        .split('\n')
                        .map((l) => l.trim())
                        .where((l) => l.isNotEmpty)
                        .map(
                          (n) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bouton vérifier
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _verification ? null : () => _verifier(afficherDialog: true),
                icon: _verification
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: Text(_verification ? 'Vérification…' : 'Vérifier les mises à jour'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: child,
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<List<String>> rows,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kOrange, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r[0], style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                  Text(r[1], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
