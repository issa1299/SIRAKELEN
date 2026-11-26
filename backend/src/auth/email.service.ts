import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { google } from 'googleapis';
import { OAuth2Client } from 'google-auth-library';

/**
 * Envoi des codes de vérification par email via GMAIL.
 *
 * Stratégie (ordre de préférence) :
 *  1. Gmail API (HTTPS, port 443) — fonctionne sur Render gratuit.
 *     Nécessite GMAIL_REFRESH_TOKEN + GOOGLE_CLIENT_ID + GOOGLE_CLIENT_SECRET.
 *  2. Gmail SMTP (ports 465/587) — fallback local ; souvent bloqué sur Render.
 *  3. Mode dev — code affiché dans les logs si rien n'est configuré.
 *
 * Le code est sauvegardé (hashé) en base AVANT l'envoi : même si Gmail échoue,
 * l'endpoint répond vite et le code reste valable 5 minutes.
 */
@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private readonly transporter?: nodemailer.Transporter;
  private readonly oauth2?: OAuth2Client;
  private readonly from: string;
  private readonly timeoutMs = 10000;
  private readonly gmailUser = 'me';

  constructor(private readonly config: ConfigService) {
    const user = config.get<string>('SMTP_USER') || '';
    const pass = config.get<string>('SMTP_PASS') || '';
    const clientId = config.get<string>('GOOGLE_CLIENT_ID') || '';
    const clientSecret = config.get<string>('GOOGLE_CLIENT_SECRET') || '';
    const refreshToken = config.get<string>('GMAIL_REFRESH_TOKEN') || '';

    this.from = config.get<string>('SMTP_FROM') || `SIRA KELEN <${user || this.gmailUser}>`;

    // 1) Gmail API (HTTPS) — prioritaire, compatible Render.
    if (clientId && clientSecret && refreshToken) {
      this.oauth2 = new google.auth.OAuth2(clientId, clientSecret);
      this.oauth2.setCredentials({ refresh_token: refreshToken });
      this.logger.log('Gmail API (HTTPS) configuré avec Refresh Token');
    } else if (user && pass) {
      // 2) Fallback SMTP (local / hébergeur autorisant le SMTP sortant).
      this.transporter = nodemailer.createTransport({
        host: 'smtp.gmail.com',
        port: 465,
        secure: true,
        auth: { user, pass },
        connectionTimeout: this.timeoutMs,
        greetingTimeout: this.timeoutMs,
        socketTimeout: this.timeoutMs,
      });
      this.logger.log('Gmail SMTP configuré (fallback, timeout ' + this.timeoutMs + 'ms)');
    } else {
      this.logger.warn('[MODE DEV] Aucun service Gmail configuré — codes dans les logs');
    }
  }

  /** Stratégie active (sans exposer les secrets) — diagnostic. */
  getStrategie(): 'gmail-api' | 'gmail-smtp' | 'dev' {
    if (this.oauth2) return 'gmail-api';
    if (this.transporter) return 'gmail-smtp';
    return 'dev';
  }

  async envoyerVerification(email: string, code: string): Promise<void> {
    const subject = 'Votre code SIRA KELEN : ' + code;
    const text = `SIRA KELEN - Votre code de vérification est : ${code}\n\nCode valable 5 minutes. Ne le partagez avec personne.`;
    const html = this.templateHtml(code);

    try {
      if (this.oauth2) {
        await this.withTimeout(this.envoyerViaApi(email, subject, text, html));
        this.logger.log(`Email envoyé à ${email} (Gmail API)`);
        return;
      }
      if (this.transporter) {
        await this.withTimeout(
          this.transporter.sendMail({ from: this.from, to: email, subject, text, html }),
        );
        this.logger.log(`Email envoyé à ${email} (Gmail SMTP)`);
        return;
      }
      this.logger.warn(`[MODE DEV] Code pour ${email} : ${code}`);
    } catch (error: any) {
      this.logger.error(`Envoi Gmail échoué: ${error?.message || error}`);
      this.logger.warn(`[FALLBACK] Code pour ${email} : ${code}`);
    }
  }

  /** Envoi via Gmail API (messages.send, base64url). */
  private async envoyerViaApi(
    to: string,
    subject: string,
    text: string,
    html: string,
  ): Promise<void> {
    const gmail = google.gmail({ version: 'v1', auth: this.oauth2 });
    const from = this.from.includes('<')
      ? this.from
      : `SIRA KELEN <${this.from}>`;
    const raw = [
      `From: ${from}`,
      `To: ${to}`,
      `Subject: =?UTF-8?B?${Buffer.from(subject).toString('base64')}?=`,
      'MIME-Version: 1.0',
      'Content-Type: text/html; charset=UTF-8',
      '',
      html,
      '',
      text,
    ].join('\r\n');
    await gmail.users.messages.send({
      userId: this.gmailUser,
      requestBody: { raw: Buffer.from(raw).toString('base64url') },
    });
  }

  /** Borne une promesse dans le temps pour ne jamais bloquer la réponse. */
  private async withTimeout<T>(promise: Promise<T>): Promise<T> {
    let timer: NodeJS.Timeout;
    const timeout = new Promise<never>((_, reject) => {
      timer = setTimeout(
        () => reject(new Error(`Gmail timeout après ${this.timeoutMs}ms`)),
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