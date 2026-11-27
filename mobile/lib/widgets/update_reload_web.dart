/// Implémentation Web : recharge la page pour activer le nouveau service worker.
import 'dart:js_interop';

@JS('location.reload')
external void _reloadPage();

Future<void> rechargerApplication() async {
  _reloadPage();
}
