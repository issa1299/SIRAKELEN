import { Injectable, Logger } from '@nestjs/common';
import * as nodemailer from 'nodemailer';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly transporter;
  private readonly config: ConfigService;

  constructor(configService: ConfigService) {
    this.config = configService;
    const host = configService.get<string>('SMTP_HOST');
    const port = parseInt(configService.get<string>('SMTP_PORT', '587'));
    const user = configService.get<string>('SMTP_USER');
    const pass = configService.get<string>('SMTP_PASS');

    if (host && user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure: port === 465,
        auth: { user, pass },
      });
      this.logger.log(`SMTP configuré: ${host}:${port}`);
    } else {
      this.transporter = null;
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
        from: `"SIRA KELE" <${this.config.get<string>('SMTP_USER')}>`,
        to: email,
        subject: 'Code de verification SIRA KELE',
        text: `Votre code de verification est : ${code}`,
        html: `<div style="font-family:Arial,sans-serif;text-align:center;padding:20px">
          <h2 style="color:#FF7700">SIRA KELE</h2>
          <p>Votre code de verification est :</p>
          <div style="font-size:32px;font-weight:bold;letter-spacing:8px;color:#FF7700">${code}</div>
          <p style="color:#999">Code valable 5 minutes</p>
        </div>`,
      });
      this.logger.log(`Email envoyé à ${email}`);
    } catch (error) {
      this.logger.error(`SMTP échoué: ${error.message}`);
      this.logger.warn(`[MODE DEV] Code pour ${email} : ${code}`);
    }
  }
}