import 'package:flutter/material.dart';
import '../main.dart';

/// Enveloppe responsive globale.
///
/// - Téléphone (< 600 dp) : rendu identique à l'application mobile, pleine largeur.
/// - Tablette (600–1100 dp) : contenu centré dans une colonne de 600 dp max.
/// - Ordinateur (> 1100 dp) : contenu centré dans une colonne de 480 dp max,
///   fond crème sur les côtés, aucun étirement.
///
/// Utilise [LayoutBuilder] pour respecter les contraintes du parent (contrairement
/// à MediaQuery.size qui ignore le parent). Peut être appliqué globalement via
/// MaterialApp.builder sans casser Navigator 1.0 ni les écrans existants.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  /// Largeur maximale sur ordinateur.
  static const double largeurDesktop = 480.0;
  /// Largeur maximale sur tablette.
  static const double largeurTablette = 600.0;
  /// Seuil tablette.
  static const double seuilTablette = 600.0;
  /// Seuil ordinateur.
  static const double seuilDesktop = 1100.0;

  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeur = constraints.maxWidth;

        // Téléphone : rendu natif sans contrainte.
        if (largeur < seuilTablette) return child;

        final maxLargeur =
            largeur >= seuilDesktop ? largeurDesktop : largeurTablette;

        return Container(
          color: kCream,
          width: double.infinity,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxLargeur),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
