import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  static Future<void> ouvrir({
    required String telephone,
    String? message,
  }) async {
    final tel = telephone.replaceAll(RegExp(r'[^0-9]'), '');
    final telFinal = tel.startsWith('223') ? tel : '223$tel';

    final uri = Uri.parse(
      'https://wa.me/$telFinal${message != null ? '?text=${Uri.encodeComponent(message)}' : ''}',
    );

    debugPrint('WhatsApp URL: $uri');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('canLaunchUrl = false pour $uri');
      }
    } catch (e) {
      debugPrint('Erreur WhatsApp: $e');
    }
  }
}
