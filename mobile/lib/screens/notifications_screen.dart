import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;
  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<dynamic>>(
        future: _charger(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kOrange));
          }
          final notifs = snapshot.data ?? [];
          if (notifs.isEmpty) {
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
                    child: Icon(Icons.notifications_none_rounded, size: 32, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune notification',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Tu seras prévenu ici dès qu\'une compatibilité est trouvée ou qu\'une demande arrive.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: kTextSecondary,
                        height: 1.5,
                      ),
                    ),
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
          'icone': Icons.group_add_rounded,
          'titre': 'Nouvelle demande',
          'texte':
              '${demandeur['prenom']} ${demandeur['nom']} souhaite rejoindre ton trajet '
                  '${(d['ad'] as Map<String, dynamic>)['depart']} → ${(d['ad'] as Map<String, dynamic>)['destination']}',
          'couleur': kOrange,
          'bg': kOrangeLight,
        });
      }
      final envoyees = await ApiService.getDemandesEnvoyees(userId);
      for (final d in envoyees) {
        final ad = d['ad'] as Map<String, dynamic>;
        final proprio = ad['proprietaire'] as Map<String, dynamic>;
        final statut = d['statut'] as String;
        if (statut == 'acceptee') {
          notifs.add({
            'icone': Icons.check_circle_outline_rounded,
            'titre': 'Demande acceptée',
            'texte':
                '${proprio['prenom']} a accepté ta demande pour ${ad['depart']} → ${ad['destination']}. Contacte-le au ${proprio['telephone']}.',
            'couleur': kGreen,
            'bg': kGreenLight,
          });
        } else if (statut == 'refusee') {
          notifs.add({
            'icone': Icons.cancel_outlined,
            'titre': 'Demande refusée',
            'texte':
                'Ta demande pour le trajet de ${proprio['prenom']} n\'a pas été retenue.',
            'couleur': kRed,
            'bg': kRedLight,
          });
        }
      }
    } catch (_) {}
    return notifs;
  }

  Widget _ligne(Map<String, dynamic> n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: n['bg'] as Color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              n['icone'] as IconData,
              size: 20,
              color: n['couleur'] as Color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n['titre'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  n['texte'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: kTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
