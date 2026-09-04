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
        return 'ORGANISÉ';
      case 'annule':
        return 'ANNULÉ';
      default:
        return statut.toUpperCase();
    }
  }

  Color _bgStatut(String statut) {
    switch (statut) {
      case 'actif':
        return kGreenLight;
      case 'en_cours_de_finalisation':
        return const Color(0xFFFFE8D4);
      case 'trajet_organise':
        return kGreen;
      default:
        return kGreyLight;
    }
  }

  Color _textStatut(String statut) {
    switch (statut) {
      case 'actif':
        return kGreen;
      case 'en_cours_de_finalisation':
        return const Color(0xFFB35A00);
      case 'trajet_organise':
        return Colors.white;
      default:
        return kTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final aujourdhui = DateTime.now();
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Mes Avis de Déplacement')),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.mesAds(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kOrange));
          }
          final ads = snapshot.data ?? [];
          if (ads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: kGreyLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.description_outlined, size: 32, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun AD publié',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
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
                _sectionTitle('EN COURS'),
                ...enCours.map((a) => _carte(a, false)),
                const SizedBox(height: 16),
              ],
              if (archives.isNotEmpty) ...[
                _sectionTitle('HISTORIQUE'),
                ...archives.map((a) => _carte(a, true)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: kTextSecondary,
        ),
      ),
    );
  }

  Widget _carte(Map<String, dynamic> a, bool archive) {
    final statut = a['statut'] as String;
    final barre = statut == 'trajet_organise' || statut == 'annule';
    return Opacity(
      opacity: archive ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _bgStatut(statut),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _libelleStatut(statut),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _textStatut(statut),
                    ),
                  ),
                ),
                Text(
                  a['role'] == 'conducteur' ? 'Conducteur' : 'Passager',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  a['role'] == 'conducteur'
                      ? Icons.directions_car_rounded
                      : Icons.person_search_rounded,
                  size: 18,
                  color: kOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${a['depart']} → ${a['destination']}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: barre ? TextDecoration.lineThrough : null,
                      color: barre ? kTextSecondary : kTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                '${a['dateDeplacement']} · ${a['heureDepart']}'
                '${a['role'] == 'conducteur' ? ' · ${a['moyenTransport']} · ${a['placesDisponibles']} place(s)' : ''}',
                style: TextStyle(fontSize: 11, color: kTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
