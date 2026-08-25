import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirakele/main.dart';

void main() {
  testWidgets('Le premier lancement affiche l onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SirakeleApp());
    // Laisse le FutureBuilder (SharedPreferences) se résoudre.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // Slide 1 du carrousel d onboarding.
    expect(find.textContaining('Réduisez vos frais'), findsOneWidget);
  });
}
