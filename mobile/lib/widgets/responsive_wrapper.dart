import 'package:flutter/material.dart';
import '../main.dart';

/// Enveloppe responsive : sur grand écran, centre le contenu dans une colonne
/// de largeur maximale ~480 dp avec fond crème, sans étirement.
/// Sur téléphone (< 480 dp), rendu identique à l'application mobile.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  /// Largeur maximale du contenu sur grand écran.
  static const double largeurMax = 480.0;

  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final largeur = MediaQuery.of(context).size.width;

    // Sur téléphone : pas de contrainte, rendu natif.
    if (largeur <= largeurMax) return child;

    // Sur grand écran : centrer le contenu.
    return Container(
      color: kCream,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: largeurMax),
          child: child,
        ),
      ),
    );
  }
}
