import 'package:flutter/material.dart';
import '../main.dart';

/// Skeleton rectangulaire pour indiquer le chargement d'un contenu.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: kGreyLight,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Skeleton circulaire (avatar, bouton circulaire, etc.).
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kGreyLight,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton d'une carte de trajet (utilisé dans Mes trajets et Accueil).
class SkeletonTripCard extends StatelessWidget {
  const SkeletonTripCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Row(
            children: [
              const SkeletonCircle(size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 180, height: 14),
                    const SizedBox(height: 6),
                    const SkeletonBox(width: 220, height: 12),
                  ],
                ),
              ),
              const SkeletonBox(width: 30, height: 20),
            ],
          ),
          const SizedBox(height: 10),
          // Titre trajet
          const SkeletonBox(width: 260, height: 18),
          const SizedBox(height: 6),
          // Sous-titre date/heure
          const SkeletonBox(width: 300, height: 14),
          const SizedBox(height: 12),
          // Statut + bouton
          Row(
            children: [
              const SkeletonBox(width: 80, height: 24),
              const Spacer(),
              const SkeletonBox(width: 120, height: 40),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton pour l'en-tête d'accueil.
class SkeletonHeader extends StatelessWidget {
  const SkeletonHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 120, height: 14),
            const SizedBox(height: 6),
            const SkeletonBox(width: 200, height: 28),
          ],
        ),
        const SkeletonCircle(size: 44),
      ],
    );
  }
}
