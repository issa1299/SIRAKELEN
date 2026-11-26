import {
  Injectable,
  UnauthorizedException,
  ForbiddenException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, randomBytes, scryptSync, timingSafeEqual } from 'crypto';
import {
  AdminRole,
  AdminPermission,
  roleAPerlission,
} from './admin-role.enum';

export interface AdminTokenPayload {
  adminId: string;
  role: AdminRole;
  prenom: string;
  exp: number;
}

/**
 * Authentification administrateur sans dépendance externe :
 *  - mot de passe haché avec scrypt (sel + hash) ; compatibilité transitoire
 *    avec les mots de passe en clair existants (admin123) pour ne pas casser
 *    l'accès, mais tout nouveau mot de passe est haché.
 *  - token HMAC-SHA256 signé avec ADMIN_JWT_SECRET, avec expiration (24 h).
 */
@Injectable()
export class AdminAuthService {
  private readonly secret: string;
  private readonly dureeTokenMs = 24 * 60 * 60 * 1000; // 24 h

  constructor(private readonly config: ConfigService) {
    this.secret =
      this.config.get<string>('ADMIN_JWT_SECRET') ||
      'sirakelen-admin-secret-a-changer-en-production';
  }

  /** Hache un mot de passe avec scrypt : "sel:hash" en hex. */
  hacherMotDePasse(motDePasse: string): string {
    const sel = randomBytes(16);
    const hash = scryptSync(motDePasse, sel, 64);
    return `${sel.toString('hex')}:${hash.toString('hex')}`;
  }

  /** Vérifie un mot de passe (hash scrypt ou clair legacy). */
  verifierMotDePasse(motDePasse: string, stocke: string | null): boolean {
    if (!stocke || !motDePasse) return false;
    if (stocke.includes(':')) {
      try {
        const [selHex, hashHex] = stocke.split(':');
        const attendu = Buffer.from(hashHex, 'hex');
        const calcule = scryptSync(motDePasse, Buffer.from(selHex, 'hex'), attendu.length);
        return attendu.length === calcule.length && timingSafeEqual(attendu, calcule);
      } catch {
        return false;
      }
    }
    // Legacy : comparaison en clair (compatibilité ascendante).
    const a = Buffer.from(stocke);
    const b = Buffer.from(motDePasse);
    return a.length === b.length && timingSafeEqual(a, b);
  }

  /** Crée un token signé HMAC avec expiration. */
  creerToken(adminId: string, role: AdminRole, prenom: string): string {
    const payload: AdminTokenPayload = {
      adminId,
      role,
      prenom: prenom || 'Administrateur',
      exp: Date.now() + this.dureeTokenMs,
    };
    const corps = Buffer.from(JSON.stringify(payload)).toString('base64url');
    const signature = this.signer(corps);
    return `${corps}.${signature}`;
  }

  /** Vérifie un token et retourne son payload ou lève 401. */
  verifierToken(token: string): AdminTokenPayload {
    if (!token || !token.includes('.')) {
      throw new UnauthorizedException('Token administrateur manquant ou invalide');
    }
    const [corps, signature] = token.split('.');
    const attendu = this.signer(corps);
    const a = Buffer.from(signature);
    const b = Buffer.from(attendu);
    if (a.length !== b.length || !timingSafeEqual(a, b)) {
      throw new UnauthorizedException('Signature du token invalide');
    }
    let payload: AdminTokenPayload;
    try {
      payload = JSON.parse(
        Buffer.from(corps, 'base64url').toString('utf8'),
      ) as AdminTokenPayload;
    } catch {
      throw new UnauthorizedException('Token illisible');
    }
    if (!payload.exp || payload.exp < Date.now()) {
      throw new UnauthorizedException('Token expiré');
    }
    return payload;
  }

  /** Vérifie qu'un rôle possède une permission, sinon 403. */
  exigerPermission(payload: AdminTokenPayload, permission: AdminPermission): void {
    if (!roleAPerlission(payload.role, permission)) {
      throw new ForbiddenException(
        `Accès refusé : permission ${permission} requise`,
      );
    }
  }

  /** Extrait le token d'un header Authorization: Bearer <token>. */
  extraireToken(header: string | undefined): string {
    if (!header) {
      throw new UnauthorizedException('En-tête Authorization manquant');
    }
    const match = header.match(/^Bearer\s+(.+)$/i);
    if (!match) {
      throw new UnauthorizedException('Format Authorization invalide');
    }
    return match[1];
  }

  private signer(corps: string): string {
    return createHmac('sha256', this.secret).update(corps).digest('base64url');
  }
}
