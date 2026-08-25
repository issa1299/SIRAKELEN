import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;
  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<dynamic>>(
        future: _charger(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kOrange));
          }
          final notifs = snapshot.data ?? [];
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 46, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Aucune notification',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'Tu seras prévenu ici dès qu’une compatibilité est trouvée ou qu’une demande arrive.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.5),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: notifs.map((n) => _ligne(n as Map<String, dynamic>)).toList(),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _charger() async {
    final notifs = <Map<String, dynamic>>[];
    try {
      final recues = await ApiService.getDemandesRecues(userId);
      for (final d in recues) {
        final demandeur = d['demandeur'] as Map<String, dynamic>;
        notifs.add({
          'icone': Icons.group_add,
          'titre': 'Nouvelle demande',
          'texte':
              '${demandeur['prenom']} ${demandeur['nom']} souhaite rejoindre ton trajet '
                  '${(d['ad'] as Map<String, dynamic>)['depart']} → ${(d['ad'] as Map<String, dynamic>)['destination']}',
          'couleur': kOrangeDark,
        });
      }
      final envoyees = await ApiService.getDemandesEnvoyees(userId);
      for (final d in envoyees) {
        final ad = d['ad'] as Map<String, dynamic>;
        final proprio = ad['proprietaire'] as Map<String, dynamic>;
        final statut = d['statut'] as String;
        if (statut == 'acceptee') {
          notifs.add({
            'icone': Icons.check_circle_outline,
            'titre': 'Demande acceptée',
            'texte':
                '${proprio['prenom']} a accepté ta demande pour ${ad['depart']} → ${ad['destination']}. Contacte-le au ${proprio['telephone']}.',
            'couleur': kGreen,
          });
        } else if (statut == 'refusee') {
          notifs.add({
            'icone': Icons.cancel_outlined,
            'titre': 'Demande refusée',
            'texte':
                'Ta demande pour le trajet de ${proprio['prenom']} n’a pas été retenue.',
            'couleur': const Color(0xFFA3392F),
          });
        }
      }
    } catch (_) {}
    return notifs;
  }

  Widget _ligne(Map<String, dynamic> n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEAE2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(n['icone'] as IconData,
                size: 17, color: n['couleur'] as Color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n['titre'] as String,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(n['texte'] as String,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
