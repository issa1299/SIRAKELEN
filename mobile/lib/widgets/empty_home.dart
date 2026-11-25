import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/publier_screen.dart';
import '../screens/parcourir_ads_screen.dart';
import '../widgets/my_trips_link.dart';

/// État vide de l'accueil : aucun trajet à venir.
class EmptyHome extends StatelessWidget {
  final String userId;
  final bool historiqueNonVide;

  const EmptyHome({
    super.key,
    required this.userId,
    this.historiqueNonVide = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: kOrangeLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: kOrange,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Aucun trajet prévu',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Publiez votre prochain déplacement, les voisins compatibles seront prévenus.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: kTextSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PublierScreen(userId: userId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Publier un trajet'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParcourirAdsScreen(userId: userId),
                    ),
                  ),
                  icon: const Icon(Icons.explore_rounded, size: 18, color: kOrange),
                  label: const Text(
                    'Voir les trajets près de moi',
                    style: TextStyle(
                      color: kOrange,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: kOrange.withAlpha(120)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (historiqueNonVide) ...[
          MyTripsLink(userId: userId, historiqueNonVide: true),
        ],
      ],
    );
  }
}
