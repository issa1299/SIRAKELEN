import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Evenement, TypeEvenement } from './evenement.entity';

@Injectable()
export class EvenementsService {
  constructor(
    @InjectRepository(Evenement)
    private readonly repo: Repository<Evenement>,
  ) {}

  async enregistrer(dto: {
    type: TypeEvenement;
    page?: string;
    plateforme?: string;
  }) {
    if (!Object.values(TypeEvenement).includes(dto.type)) {
      throw new BadRequestException('Type d\'événement invalide');
    }
    await this.repo.save(
      this.repo.create({
        type: dto.type,
        page: dto.page?.slice(0, 120) || null,
        plateforme: dto.plateforme?.slice(0, 20) || null,
      }),
    );
    return { enregistre: true };
  }

  async compter(type: TypeEvenement): Promise<number> {
    return this.repo.count({ where: { type } });
  }

  /** Série journalière réelle sur les N derniers jours (format YYYY-MM-DD). */
  async serie(type: TypeEvenement, jours = 30) {
    const depuis = new Date(Date.now() - Math.min(Math.max(jours, 1), 90) * 86_400_000);
    return this.repo
      .createQueryBuilder('e')
      .select(`to_char(e."creeLe", 'YYYY-MM-DD')`, 'jour')
      .addSelect('COUNT(*)::int', 'total')
      .where('e.type = :type', { type })
      .andWhere('e."creeLe" >= :depuis', { depuis })
      .groupBy('jour')
      .orderBy('jour', 'ASC')
      .getRawMany();
  }

  async totaux() {
    const types = Object.values(TypeEvenement);
    const resultat: Record<string, number> = {};
    await Promise.all(
      types.map(async (t) => {
        resultat[t] = await this.compter(t);
      }),
    );
    return resultat;
  }
}
