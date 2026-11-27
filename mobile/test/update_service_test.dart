import 'package:flutter_test/flutter_test.dart';
import 'package:sirakele/services/update_service.dart';

AppVersionInfo version(String v, int build, {String plateforme = 'android'}) {
  return AppVersionInfo(
    id: 'id-$v-$build',
    version: v,
    buildNumber: build,
    plateforme: plateforme,
    apkUrl: 'https://example.test/app.apk',
    notes: 'Nouveauté',
    datePublication: DateTime(2026, 11, 27),
    obligatoire: false,
  );
}

void main() {
  group('comparaison version / build (installé 1.0.1+2)', () {
    test('aucune version -> aucune mise à jour', () {
      expect(UpdateService.miseAJourDisponible(null), isFalse);
    });

    test('build supérieur au build installé (2) -> mise à jour', () {
      expect(UpdateService.miseAJourDisponible(version('1.0.2', 3)), isTrue);
    });

    test('build égal et version égale -> aucune mise à jour', () {
      expect(UpdateService.miseAJourDisponible(version('1.0.1', 2)), isFalse);
    });

    test('build égal et version supérieure -> mise à jour', () {
      expect(UpdateService.miseAJourDisponible(version('1.0.2', 2)), isTrue);
      expect(UpdateService.miseAJourDisponible(version('2.0.0', 2)), isTrue);
    });

    test('build égal et version inférieure -> aucune mise à jour', () {
      expect(UpdateService.miseAJourDisponible(version('1.0.0', 2)), isFalse);
    });

    test('build inférieur -> aucune mise à jour (build fait foi)', () {
      expect(UpdateService.miseAJourDisponible(version('9.0.0', 1)), isFalse);
    });

    test('comparaison numérique des segments (1.10.0 > 1.0.1)', () {
      expect(UpdateService.miseAJourDisponible(version('1.10.0', 2)), isTrue);
    });

    test('versions à segments différents (1.2 > 1.0.1)', () {
      expect(UpdateService.miseAJourDisponible(version('1.2', 2)), isTrue);
    });

    test('suffixe de build dans la chaîne ignoré (1.0.1+3 = 1.0.1)', () {
      expect(UpdateService.miseAJourDisponible(version('1.0.1+3', 2)), isFalse);
    });

    test('plateforme web acceptée par la comparaison', () {
      expect(
        UpdateService.miseAJourDisponible(
          version('1.1.0', 3, plateforme: 'web'),
        ),
        isTrue,
      );
    });
  });
}
