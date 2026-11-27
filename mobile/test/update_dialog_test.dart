import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirakele/services/update_service.dart';
import 'package:sirakele/widgets/update_checker.dart';
import 'package:sirakele/widgets/update_dialog.dart';

AppVersionInfo fakeVersion({bool obligatoire = false, String plateforme = 'android'}) {
  return AppVersionInfo(
    id: 'test-id-$obligatoire-$plateforme',
    version: '1.0.2',
    buildNumber: 3,
    plateforme: plateforme,
    apkUrl: 'https://example.test/app.apk',
    tailleOctets: 57640386,
    notes: 'Nouveauté A\nNouveauté B',
    datePublication: DateTime(2026, 11, 26),
    obligatoire: obligatoire,
  );
}

Widget appAvecDialog(AppVersionInfo v) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => UpdateDialog.show(context, version: v),
          child: const Text('ouvrir'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('mise à jour FACULTATIVE : Télécharger + Plus tard', (tester) async {
    await tester.pumpWidget(appAvecDialog(fakeVersion()));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Mise à jour disponible'), findsOneWidget);
    expect(find.text('Plus tard'), findsOneWidget);
    expect(find.text('Télécharger'), findsOneWidget);
    expect(find.text('Nouveauté A'), findsOneWidget);
    expect(find.text('Taille : 55.0 Mo'), findsOneWidget);

    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    expect(find.text('Mise à jour disponible'), findsNothing);
  });

  testWidgets('mise à jour OBLIGATOIRE : pas de Plus tard', (tester) async {
    await tester.pumpWidget(appAvecDialog(fakeVersion(obligatoire: true)));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Mise à jour disponible'), findsOneWidget);
    expect(find.text('Mise à jour obligatoire'), findsOneWidget);
    expect(find.text('Plus tard'), findsNothing);
    expect(find.text('Télécharger'), findsOneWidget);
  });

  testWidgets('Plus tard empêche la réapparition pendant la session', (tester) async {
    final v = fakeVersion();
    await tester.pumpWidget(MaterialApp(
      home: UpdateChecker(
        verifier: () async => v,
        child: const Scaffold(body: Center(child: Text('app'))),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Mise à jour disponible'), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    expect(find.text('Mise à jour disponible'), findsNothing);

    // Plusieurs allers-retours arrière-plan / premier plan.
    for (int i = 0; i < 3; i++) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
    }
    expect(find.text('Mise à jour disponible'), findsNothing);
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('nouvelle version dans la session -> nouveau dialogue', (tester) async {
    final premiere = fakeVersion();
    final suivante = AppVersionInfo(
      id: 'autre-id',
      version: '1.0.3',
      buildNumber: 4,
      plateforme: 'android',
      apkUrl: 'https://example.test/app.apk',
      notes: 'Autre version',
      datePublication: DateTime(2026, 11, 27),
      obligatoire: false,
    );
    AppVersionInfo courante = premiere;
    await tester.pumpWidget(MaterialApp(
      home: UpdateChecker(
        verifier: () async => courante,
        child: const Scaffold(body: Text('app')),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Version 1.0.2'), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();

    courante = suivante;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.textContaining('Version 1.0.3'), findsOneWidget);
  });

  testWidgets('web : dialogue propose Recharger et non Télécharger (widget Android testé)',
      (tester) async {
    // kIsWeb est false dans flutter test (plateforme native) : on vérifie
    // uniquement que la logique accepte une version plateforme=web.
    final v = fakeVersion(plateforme: 'web');
    await tester.pumpWidget(MaterialApp(
      home: UpdateChecker(
        verifier: () async => v,
        child: const Scaffold(body: Text('app')),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Mise à jour disponible'), findsOneWidget);
    expect(find.text('Télécharger'), findsOneWidget);
  });
}
