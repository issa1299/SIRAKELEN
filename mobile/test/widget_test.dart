import 'package:flutter_test/flutter_test.dart';
import 'package:sirakele/main.dart';

void main() {
  testWidgets('L écran de bienvenue affiche le titre', (tester) async {
    await tester.pumpWidget(const SirakeleApp());
    expect(find.textContaining('Partagez la route'), findsOneWidget);
  });
}
