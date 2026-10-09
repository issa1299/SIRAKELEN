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
        subject: 'Votre code SIRA KELEN : ' + code,
        text: `SIRA KELEN - Partagez la route. Partagez le coût.\n\nVotre code de vérification est : ${code}\n\nCode valable 5 minutes. Ne le partagez avec personne.`,
        html: `<!DOCTYPE html><html><body style="margin:0;padding:0;background:#FAF8F2;font-family:Arial,Helvetica,sans-serif">
          <div style="max-width:480px;margin:0 auto;padding:32px 16px">
            <div style="background:linear-gradient(135deg,#FF7700,#E25F00);border-radius:20px 20px 0 0;padding:32px;text-align:center">
              <div style="font-size:24px;font-weight:900;color:#ffffff;letter-spacing:-.5px">SIRA KELEN</div>
              <div style="font-size:12px;color:#FFE3C2;margin-top:6px">Partagez la route. Partagez le coût.</div>
            </div>
            <div style="background:#ffffff;border:1px solid #E7E3D6;border-top:none;border-radius:0 0 20px 20px;padding:36px 32px;text-align:center">
              <div style="font-size:15px;color:#4D493D">Votre code de vérification est :</div>
              <div style="font-size:44px;font-weight:900;letter-spacing:14px;color:#FF7700;margin:20px 0 8px;padding-left:14px">${code}</div>
              <div style="display:inline-block;font-size:12px;font-weight:700;color:#B35A00;background:#FFF3E6;border-radius:20px;padding:6px 16px">Valable 5 minutes</div>
              <p style="font-size:13px;color:#8A877A;line-height:1.6;margin:24px 0 0">Ne partagez jamais ce code.<br>Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
            </div>
            <div style="text-align:center;font-size:11px;color:#8A877A;margin-top:20px">SIRA KELEN — Covoiturage urbain · Bamako, Mali</div>
          </div>
        </body></html>`,
      });

      this.logger.log(`Email envoyé à ${email}`);
    } catch (error: any) {
      this.logger.error(`Gmail SMTP échoué: ${error.message}`);
      this.logger.warn(`[MODE DEV] Code pour ${email} : ${code}`);
    }
  }
}
