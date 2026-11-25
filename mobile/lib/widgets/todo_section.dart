import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../screens/mes_trajets_screen.dart';

/// Section « À traiter » : max 2 lignes, masquée si vide.
/// Affiche les demandes reçues sans réponse et les messages non lus.
class TodoSection extends StatelessWidget {
  final List<Map<String, dynamic>> demandesRecues;
  final int nbMessagesNonLus;
  final String userId;
  final VoidCallback onRepondre;
  final VoidCallback onVoirNotifications;

  const TodoSection({
    super.key,
    required this.demandesRecues,
    required this.nbMessagesNonLus,
    required this.userId,
    required this.onRepondre,
    required this.onVoirNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final nbElements = demandesRecues.length + nbMessagesNonLus;
    if (nbElements == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(nbElements),
        const SizedBox(height: 8),
        // Ligne 1 : demande reçue sans réponse
        if (demandesRecues.isNotEmpty) ...[
          _ligneDemandeRecue(demandesRecues.first, context),
        ],
        // Ligne 2 : message non lu ou "+N autres"
        if (nbMessagesNonLus > 0 && demandesRecues.isEmpty) ...[
          _ligneMessage(context),
        ] else if (nbElements > 2) ...[
          _lignePlusN(context),
        ],
      ],
    );
  }

  Widget _sectionTitle(int nbElements) {
    return Row(
      children: [
        const Text(
          'À traiter',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: kTextPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kOrangeLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$nbElements',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: kOrange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _ligneDemandeRecue(Map<String, dynamic> d, BuildContext context) {
    final demandeur = d['demandeur'] as Map<String, dynamic>;
    final ad = d['ad'] as Map<String, dynamic>;
    final heureDepart = ad['heureDepart'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onRepondre,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: kOrangeLight,
                  backgroundImage: (demandeur['photoUrl'] != null &&
                          (demandeur['photoUrl'] as String).isNotEmpty)
                      ? NetworkImage(
                          ApiService.resolvePhoto(demandeur['photoUrl'] as String)!)
                      : null,
                  child: (demandeur['photoUrl'] == null ||
                          (demandeur['photoUrl'] as String).isEmpty)
                      ? Text(
                          '${demandeur['prenom'][0]}',
                          style: const TextStyle(
                            color: kOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demande de ${demandeur['prenom']}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: kTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Départ à $heureDepart',
                            style: TextStyle(
                              fontSize: 11,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kOrangeLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Répondre',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: kOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ligneMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: kGreyLight,
            child: Icon(Icons.message_rounded, color: kTextSecondary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message non lu',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Consultez vos conversations.',
                  style: TextStyle(
                    fontSize: 11,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lignePlusN(BuildContext context) {
    final nbAutres = demandesRecues.length + nbMessagesNonLus - 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.more_horiz_rounded,
            color: kTextSecondary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MesTrajetsScreen(
                      userId: userId,
                      initialTab: 1, // onglet Demandes
                    ),
                  ),
                );
              },
              child: Text(
                '+$nbAutres autres',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kOrange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
