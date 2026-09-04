import {
  BadRequestException,
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { createHash, randomInt } from 'crypto';
import { CodeVerification } from './code-verification.entity';
import { SmsService } from './sms.service';
import { EmailService } from './email.service';
import { UsersService } from '../users/users.service';

const DUREE_CODE_MINUTES = 5;
const MAX_TENTATIVES = 3;
const MAX_CODES_PAR_HEURE = 5;

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectRepository(CodeVerification)
    private readonly codesRepository: Repository<CodeVerification>,
    private readonly smsService: SmsService,
    private readonly emailService: EmailService,
    private readonly usersService: UsersService,
  ) {}

  // === MÉTHODES SMS (déjà existantes, gardées à l'identique) ===
  async envoyerCode(telephone: string): Promise<{ message: string }> {
    // Anti-abus : max 5 codes par heure par numéro.
    const ilYAUneHeure = new Date(Date.now() - 60 * 60 * 1000);
    const recents = await this.codesRepository.count({
      where: { telephone, creeLe: LessThan(ilYAUneHeure) },
    });
    if (recents >= MAX_CODES_PAR_HEURE) {
      throw new HttpException(
        'Trop de codes demandés. Réessaie dans une heure.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const code = randomInt(1000, 10000).toString();
    const expireLe = new Date(Date.now() + DUREE_CODE_MINUTES * 60 * 1000);

    await this.codesRepository.delete({ telephone });
    await this.codesRepository.save({
      telephone,
      codeHash: this.hasher(code),
      tentatives: 0,
      expireLe,
    });

    await this.smsService.envoyerCode(telephone, code);
    return { message: 'Code envoyé par SMS' };
  }

  async verifierCode(
    telephone: string,
    code: string,
  ): Promise<{ verifie: boolean }> {
    const enregistrement = await this.codesRepository.findOne({
      where: { telephone },
    });

    if (!enregistrement) {
      throw new BadRequestException(
        'Aucun code actif. Demande un nouveau code.',
      );
    }
    if (enregistrement.expireLe < new Date()) {
      await this.codesRepository.delete({ telephone });
      throw new BadRequestException('Code expiré. Demande un nouveau code.');
    }
    if (enregistrement.tentatives >= MAX_TENTATIVES) {
      await this.codesRepository.delete({ telephone });
      throw new UnauthorizedException(
        'Trop de tentatives. Demande un nouveau code.',
      );
    }

    if (enregistrement.codeHash !== this.hasher(code)) {
      enregistrement.tentatives += 1;
      await this.codesRepository.save(enregistrement);
      const restantes = MAX_TENTATIVES - enregistrement.tentatives;
      throw new BadRequestException(
        `Code incorrect. ${restantes} tentative(s) restante(s).`,
      );
    }

    await this.codesRepository.delete({ telephone });
    return { verifie: true };
  }

  // === NOUVELLES MÉTHODES EMAIL ===
  async envoyerCodeEmail(email: string): Promise<{ message: string }> {
    // Anti-abus : max 5 codes par heure par email.
    const ilYAUneHeure = new Date(Date.now() - 60 * 60 * 1000);
    const recents = await this.codesRepository.count({
      where: { email, creeLe: LessThan(ilYAUneHeure) },
    });
    if (recents >= MAX_CODES_PAR_HEURE) {
      throw new HttpException(
        'Trop de codes demandés. Réessaie dans une heure.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const code = randomInt(1000, 10000).toString();
    const expireLe = new Date(Date.now() + DUREE_CODE_MINUTES * 60 * 1000);

    await this.codesRepository.delete({ email });
    await this.codesRepository.save({
      email,
      codeHash: this.hasher(code),
      tentatives: 0,
      expireLe,
    });

    // Envoi par email (SMTP Gmail)
    await this.emailService.envoyerVerification(email, code);
    return { message: 'Code envoyé par email' };
  }

  async verifierCodeEmail(
    email: string,
    code: string,
  ): Promise<{ verifie: boolean }> {
    const enregistrement = await this.codesRepository.findOne({
      where: { email },
    });

    if (!enregistrement) {
      throw new BadRequestException(
        'Aucun code actif. Demande un nouveau code.',
      );
    }
    if (enregistrement.expireLe < new Date()) {
      await this.codesRepository.delete({ email });
      throw new BadRequestException('Code expiré. Demande un nouveau code.');
    }
    if (enregistrement.tentatives >= MAX_TENTATIVES) {
      await this.codesRepository.delete({ email });
      throw new UnauthorizedException(
        'Trop de tentatives. Demande un nouveau code.',
      );
    }

    if (enregistrement.codeHash !== this.hasher(code)) {
      enregistrement.tentatives += 1;
      await this.codesRepository.save(enregistrement);
      const restantes = MAX_TENTATIVES - enregistrement.tentatives;
      throw new BadRequestException(
        `Code incorrect. ${restantes} tentative(s) restante(s).`,
      );
    }

    await this.codesRepository.delete({ email });
    return { verifie: true };
  }

  // === CODE DE RÉCUPÉRATION ===
  async definirCodeRecuperation(
    telephone: string,
    code: string,
  ): Promise<{ message: string }> {
    const user = await this.usersService.findByTelephone(telephone);
    if (!user) {
      throw new BadRequestException('Aucun compte associé à ce numéro');
    }
    await this.usersService.definirCodeRecuperation(user.id, code);
    return { message: 'Code de récupération enregistré' };
  }

  async verifierCodeRecuperation(
    telephone: string,
    code: string,
  ): Promise<{ id: string; prenom: string }> {
    const user = await this.usersService.verifierCodeRecuperation(telephone, code);
    if (!user) {
      throw new BadRequestException('Code de récupération incorrect');
    }
    return { id: user.id, prenom: user.prenom };
  }

  private hasher(code: string): string {
    return createHash('sha256').update(code).digest('hex');
  }
}