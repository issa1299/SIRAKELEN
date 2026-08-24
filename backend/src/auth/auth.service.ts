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
  ) {}

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

  private hasher(code: string): string {
    return createHash('sha256').update(code).digest('hex');
  }
}
