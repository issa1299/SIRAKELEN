import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class MesAdScreen extends StatelessWidget {
  final String userId;
  const MesAdScreen({super.key, required this.userId});

  String _libelleStatut(String statut) {
    switch (statut) {
      case 'actif':
        return 'ACTIF';
      case 'en_cours_de_finalisation':
        return 'EN COURS';
      case 'trajet_organise':
        return 'TRAJET ORGANISÉ';
      case 'annule':
        return 'ANNULÉ';
      default:
        return statut.toUpperCase();
    }
  }

  Color _bgStatut(String statut) {
    switch (statut) {
      case 'actif':
        return const Color(0xFFE2F2E5);
      case 'en_cours_de_finalisation':
        return const Color(0xFFFFE8D4);
      case 'trajet_organise':
        return kGreen;
      default:
        return const Color(0xFFEFEDE5);
    }
  }

  Color _textStatut(String statut) {
    switch (statut) {
      case 'actif':
        return const Color(0xFF125A1E);
      case 'en_cours_de_finalisation':
        return const Color(0xFFB35A00);
      case 'trajet_organise':
        return Colors.white;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final aujourdhui = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Avis de Déplacement')),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.mesAds(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kOrange));
          }
          final ads = snapshot.data ?? [];
          if (ads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined,
                      size: 44, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Aucun AD publié',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
            );
          }
          final enCours = ads
              .where((a) =>
                  a['statut'] == 'actif' ||
                  a['statut'] == 'en_cours_de_finalisation' ||
                  a['statut'] == 'trajet_organise')
              .toList();
          final archives = ads.where((a) {
            if (a['statut'] == 'annule') return true;
            final d = DateTime.tryParse(a['dateDeplacement'] as String);
            return d != null &&
                d.isBefore(DateTime(aujourdhui.year, aujourdhui.month,
                    aujourdhui.day));
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (enCours.isNotEmpty) ...[
                Text('EN COURS',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                ...enCours.map((a) => _carte(a, false)),
                const SizedBox(height: 16),
              ],
              if (archives.isNotEmpty) ...[
                Text('HISTORIQUE',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                ...archives.map((a) => _carte(a, true)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _carte(Map<String, dynamic> a, bool archive) {
    final statut = a['statut'] as String;
    final barre = statut == 'trajet_organise' || statut == 'annule';
    return Opacity(
      opacity: archive ? 0.65 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDEAE2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _bgStatut(statut),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_libelleStatut(statut),
                      style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: _textStatut(statut))),
                ),
                Text(
                  a['role'] == 'conducteur' ? 'Conducteur' : 'Passager',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              '${a['depart']} → ${a['destination']}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                decoration: barre ? TextDecoration.lineThrough : null,
                color: barre ? Colors.grey.shade600 : const Color(0xFF1D1D1B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${a['dateDeplacement']} · ${a['heureDepart']}'
              '${a['role'] == 'conducteur' ? ' · ${a['moyenTransport']} · ${a['placesDisponibles']} place(s)' : ''}',
              style: TextStyle(
                  fontSize: 10.5, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
