import 'package:flutter_test/flutter_test.dart';
import 'package:sirakele/services/notification_read_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('les notifications lues ne comptent plus dans le badge', () async {
    await NotificationReadService.marquerCommeLues(['a', 'b']);

    final restants = await NotificationReadService.nonLues([
      {'id': 'a'},
      {'id': 'b'},
      {'id': 'c'},
    ]);

    expect(restants.length, 1);
    expect(restants.first['id'], 'c');
  });

  test('marquer plusieurs fois n ajoute pas de doublons', () async {
    await NotificationReadService.marquerCommeLues(['a']);
    await NotificationReadService.marquerCommeLues(['a', 'b']);

    final restants = await NotificationReadService.nonLues([
      {'id': 'a'},
      {'id': 'b'},
    ]);
    expect(restants, isEmpty);
  });

  test('une notification sans id n est pas considerée comme lue', () async {
    final restants = await NotificationReadService.nonLues([
      {'id': ''},
    ]);
    expect(restants.length, 1);
  });
}
