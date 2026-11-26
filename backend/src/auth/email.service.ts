import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { Resend } from 'resend';

/**
 * Envoi des codes de verification par email.
 *
 * Stratégie (ordre de préférence) :
 *  1. Resend (API HTTPS) — recommandé sur Render : aucun port SMTP bloqué.
 *  2. Gmail SMTP — fallback local, avec timeout court pour ne jamais bloquer la réponse.
 *  3. Mode dev — code affiché dans les logs si aucun service n'est configuré.
 *
 * Dans TOUS les cas l'envoi est borné dans le temps : l'endpoint API répond
 * rapidement même si le fournisseur d'email est indisponible.
 */
@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly transporter?: nodemailer.Transporter;
  private readonly resend?: Resend;
  private readonly from: string;
  private readonly timeoutMs = 8000;

  constructor(private readonly config: ConfigService) {
    const user = config.get<string>('SMTP_USER') || '';
    const pass = config.get<string>('SMTP_PASS') || '';
    const resendKey = config.get<string>('RESEND_API_KEY') || '';

    this.from = config.get<string>('SMTP_FROM') || `SIRA KELEN <${user}>`;

    if (resendKey) {
      this.resend = new Resend(resendKey);
      this.logger.log('Resend API configuré (envoi email HTTPS)');
    } else if (user && pass) {
      this.transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: { user, pass },
        connectionTimeout: this.timeoutMs,
        greetingTimeout: this.timeoutMs,
        socketTimeout: this.timeoutMs,
      });
      this.logger.log('Gmail SMTP configuré (timeout ' + this.timeoutMs + 'ms)');
    } else {
      this.logger.warn('[MODE DEV] Aucun service email configuré — codes dans les logs');
    }
  }

  async envoyerVerification(email: string, code: string): Promise<void> {
    const html = this.templateHtml(code);
    const text = `SIRA KELEN - Votre code de vérification est : ${code}\n\nCode valable 5 minutes. Ne le partagez avec personne.`;

    try {
      if (this.resend) {
        await this.withTimeout(
          this.resend.emails.send({
            from: this.from.includes('<')
              ? this.from
              : `SIRA KELEN <${this.from}>`,
            to: [email],
            subject: 'Votre code SIRA KELEN : ' + code,
            html,
            text,
          }),
          'Resend',
        );
        this.logger.log(`Email envoyé à ${email} (Resend)`);
        return;
      }

      if (this.transporter) {
        await this.withTimeout(
          this.transporter.sendMail({
            from: this.from,
            to: email,
            subject: 'Votre code SIRA KELEN : ' + code,
            text,
            html,
          }),
          'Gmail SMTP',
        );
        this.logger.log(`Email envoyé à ${email} (Gmail)`);
        return;
      }

      // Mode dev : pas de service, on log le code pour permettre la connexion.
      this.logger.warn(`[MODE DEV] Code pour ${email} : ${code}`);
    } catch (error: any) {
      // Ne jamais faire échouer l'endpoint : le code est déjà en base,
      // l'utilisateur peut réessayer ou le code est visible en dev.
      this.logger.error(`Envoi email échoué: ${error?.message || error}`);
      this.logger.warn(`[FALLBACK] Code pour ${email} : ${code}`);
    }
  }

  /** borne une promesse dans le temps pour ne jamais bloquer l'endpoint. */
  private async withTimeout<T>(promise: Promise<T>, label: string): Promise<T> {
    let timer: NodeJS.Timeout;
    const timeout = new Promise<never>((_, reject) => {
      timer = setTimeout(
        () => reject(new Error(`${label} timeout après ${this.timeoutMs}ms`)),
        this.timeoutMs,
      );
    });
    try {
      return await Promise.race([promise, timeout]);
    } finally {
      clearTimeout(timer!);
    }
  }

  private templateHtml(code: string): string {
    return `<!DOCTYPE html><html><body style="margin:0;padding:0;background:#FAF8F2;font-family:Arial,Helvetica,sans-serif">
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
    </body></html>`;
  }
}