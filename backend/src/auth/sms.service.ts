import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Envoi de SMS via Twilio.
 * Si les identifiants ne sont pas dans .env, on affiche le code dans la
 * console du backend (mode dev) pour tester tout le parcours sans compte.
 */
@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);

  constructor(private readonly config: ConfigService) {}

  private get twilioActif(): boolean {
    return Boolean(
      this.config.get('TWILIO_SID') &&
        this.config.get('TWILIO_TOKEN') &&
        this.config.get('TWILIO_NUMERO'),
    );
  }

  async envoyerCode(telephone: string, code: string): Promise<void> {
    const message = `SIRA KELE : votre code de verification est ${code}. Valable 5 minutes.`;

    if (!this.twilioActif) {
      // MODE DEV : pas d'identifiants Twilio -> le code s'affiche dans la console.
      this.logger.warn(
        `[MODE DEV] Code pour +223 ${telephone} : ${code} (Twilio non configuré)`,
      );
      return;
    }

    const sid = this.config.get<string>('TWILIO_SID');
    const token = this.config.get<string>('TWILIO_TOKEN');
    const numero = this.config.get<string>('TWILIO_NUMERO');
    const destinataire = `+223${telephone}`;

    const params = new URLSearchParams({
      To: destinataire,
      From: numero ?? '',
      Body: message,
    });
    const auth = Buffer.from(`${sid}:${token}`).toString('base64');

    const response = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params.toString(),
      },
    );

    if (!response.ok) {
      const detail = await response.text();
      this.logger.error(`Échec envoi SMS Twilio : ${detail}`);
      throw new Error('Échec de l’envoi du SMS');
    }
  }
}
