import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly resend: Resend | null;
  private readonly from: string;

  constructor(private readonly config: ConfigService) {
    const apiKey = config.get<string>('RESEND_API_KEY');
    this.from = config.get<string>('RESEND_FROM') || 'SIRA KELEN <onboarding@resend.dev>';

    if (apiKey) {
      this.resend = new Resend(apiKey);
      this.logger.log('Resend configuré');
    } else {
      this.resend = null;
      this.logger.warn('[MODE DEV] RESEND_API_KEY non défini — codes dans la console');
    }
  }

  async envoyerVerification(email: string, code: string): Promise<void> {
    if (!this.resend) {
      this.logger.warn(`[MODE DEV] Code pour ${email} : ${code}`);
      return;
    }

    try {
      await this.resend.emails.send({
        from: this.from,
        to: email,
        subject: 'Code de vérification SIRA KELEN',
        html: `<div style="font-family:Arial,sans-serif;text-align:center;padding:20px">
          <h2 style="color:#FF7700">SIRA KELEN</h2>
          <p>Votre code de vérification est :</p>
          <div style="font-size:32px;font-weight:bold;letter-spacing:8px;color:#FF7700">${code}</div>
          <p style="color:#999">Code valable 5 minutes</p>
        </div>`,
      });
      this.logger.log(`Email envoyé à ${email}`);
    } catch (error: any) {
      this.logger.error(`Resend échoué: ${error.message}`);
      this.logger.warn(`[MODE DEV] Code pour ${email} : ${code}`);
    }
  }
}
