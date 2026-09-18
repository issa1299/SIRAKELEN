import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly transporter: nodemailer.Transporter;
  private readonly from: string;

  constructor(private readonly config: ConfigService) {
    const user = config.get<string>('SMTP_USER') || '';
    const pass = config.get<string>('SMTP_PASS') || '';

    this.from = config.get<string>('SMTP_FROM') || `SIRA KELEN <${user}>`;

    if (user && pass) {
      this.transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: { user, pass },
      });
      this.logger.log('Gmail SMTP configuré');
    } else {
      this.logger.warn('[MODE DEV] SMTP non configuré — codes dans la console');
    }
  }

  async envoyerVerification(email: string, code: string): Promise<void> {
    if (!this.transporter) {
      this.logger.warn(`[MODE DEV] Code pour ${email} : ${code}`);
      return;
    }

    try {
      await this.transporter.sendMail({
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
      this.logger.error(`Gmail SMTP échoué: ${error.message}`);
      this.logger.warn(`[MODE DEV] Code pour ${email} : ${code}`);
    }
  }
}
