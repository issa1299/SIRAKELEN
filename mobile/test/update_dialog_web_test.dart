// Test Web : s'exécute réellement avec `flutter test --platform chrome`.
// Sur la VM Dart, kIsWeb est false : les tests sont neutralisés pour ne pas
// faire échouer la suite par défaut.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirakele/services/update_service.dart';
import 'package:sirakele/widgets/update_checker.dart';
import 'package:sirakele/widgets/update_dialog.dart';

AppVersionInfo versionWeb() => AppVersionInfo(
      id: 'web-test',
      version: '1.0.1',
      buildNumber: 2,
      plateforme: 'web',
      apkUrl: null,
      notes: 'Nouveautés Web',
      datePublication: DateTime(2026, 11, 26),
      obligatoire: false,
    );

void main() {
  testWidgets('Web : la boîte propose Recharger (pas Télécharger)', (tester) async {
    if (!kIsWeb) return;
    await tester.pumpWidget(MaterialApp(
      home: UpdateChecker(
        verifier: () async => versionWeb(),
        child: const Scaffold(body: Text('app web')),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Mise à jour disponible'), findsOneWidget);
    expect(find.text('Recharger'), findsOneWidget);
    expect(find.text('Télécharger'), findsNothing);
    expect(find.text('Plus tard'), findsOneWidget);
  });

  testWidgets('Web obligatoire : pas de Plus tard', (tester) async {
    if (!kIsWeb) return;
    final v = versionWeb();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => UpdateDialog.show(
              context,
              version: AppVersionInfo(
                id: v.id,
                version: v.version,
                buildNumber: v.buildNumber,
                plateforme: v.plateforme,
                apkUrl: v.apkUrl,
                notes: v.notes,
                datePublication: v.datePublication,
                obligatoire: true,
              ),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('Recharger'), findsOneWidget);
    expect(find.text('Plus tard'), findsNothing);
  });
}
