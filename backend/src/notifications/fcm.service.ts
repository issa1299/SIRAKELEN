import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createSign } from 'crypto';

interface CompteService {
  project_id: string;
  client_email: string;
  private_key: string;
}

/**
 * Envoi FCM via l'API HTTP v1 (OAuth2 signé avec la clé du compte de service).
 * Aucune dépendance supplémentaire. Si FCM_SERVICE_ACCOUNT_JSON n'est pas
 * configuré, aucun push n'est prétendu envoyé (report honnête dans le résultat).
 */
@Injectable()
export class FcmService {
  private readonly logger = new Logger(FcmService.name);
  private compte: CompteService | null = null;
  private accessToken: { valeur: string; expireLe: number } | null = null;

  constructor(private readonly config: ConfigService) {
    const brut = this.config.get<string>('FCM_SERVICE_ACCOUNT_JSON');
    if (brut) {
      try {
        const parse = JSON.parse(brut) as CompteService;
        if (parse.project_id && parse.client_email && parse.private_key) {
          this.compte = parse;
        }
      } catch {
        this.logger.warn('FCM_SERVICE_ACCOUNT_JSON invalide : FCM désactivé');
      }
    }
  }

  get configure(): boolean {
    return !!this.compte;
  }

  private async obtenirToken(): Promise<string | null> {
    if (!this.compte) return null;
    if (this.accessToken && this.accessToken.expireLe > Date.now() + 60_000) {
      return this.accessToken.valeur;
    }
    const maintenant = Math.floor(Date.now() / 1000);
    const enTete = Buffer.from(
      JSON.stringify({ alg: 'RS256', typ: 'JWT' }),
    ).toString('base64url');
    const charge = Buffer.from(
      JSON.stringify({
        iss: this.compte.client_email,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
        aud: 'https://oauth2.googleapis.com/token',
        iat: maintenant,
        exp: maintenant + 3600,
      }),
    ).toString('base64url');
    const aSigner = `${enTete}.${charge}`;
    const signeur = createSign('RSA-SHA256');
    signeur.update(aSigner);
    const signature = signeur.sign(this.compte.private_key, 'base64url');

    try {
      const reponse = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          assertion: `${aSigner}.${signature}`,
        }).toString(),
      });
      if (!reponse.ok) {
        this.logger.warn(`FCM OAuth ${reponse.status}`);
        return null;
      }
      const donnees = (await reponse.json()) as {
        access_token: string;
        expires_in: number;
      };
      this.accessToken = {
        valeur: donnees.access_token,
        expireLe: Date.now() + (donnees.expires_in - 120) * 1000,
      };
      return this.accessToken.valeur;
    } catch (e) {
      this.logger.warn(`FCM OAuth erreur : ${(e as Error).message}`);
      return null;
    }
  }

  async envoyer(token: string, titre: string, corps: string): Promise<boolean> {
    const oauth = await this.obtenirToken();
    if (!oauth || !this.compte) return false;
    try {
      const reponse = await fetch(
        `https://fcm.googleapis.com/v1/projects/${this.compte.project_id}/messages:send`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${oauth}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message: { token, notification: { title: titre, body: corps } },
          }),
        },
      );
      if (!reponse.ok) {
        const texte = await reponse.text();
        this.logger.warn(`FCM envoi ${reponse.status} : ${texte.slice(0, 200)}`);
        return false;
      }
      return true;
    } catch (e) {
      this.logger.warn(`FCM envoi erreur : ${(e as Error).message}`);
      return false;
    }
  }
}
