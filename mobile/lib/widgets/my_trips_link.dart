import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/mes_trajets_screen.dart';

/// Ligne « Tous mes trajets » avec bordure pointée et chevron.
/// Ouvre l'écran Mes trajets.
class MyTripsLink extends StatelessWidget {
  final String userId;
  final bool historiqueNonVide;

  const MyTripsLink({
    super.key,
    required this.userId,
    this.historiqueNonVide = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!historiqueNonVide) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MesTrajetsScreen(userId: userId),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: kTextSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tous mes trajets',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Passés, annulés, demandes envoyées',
                        style: TextStyle(
                          fontSize: 11,
                          color: kTextSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: kOrange,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
