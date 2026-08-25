import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Signalement, StatutSignalement } from '../signalements/signalement.entity';
import { UsersService } from '../users/users.service';

@Injectable()
export class SignalementsService {
  constructor(
    @InjectRepository(Signalement)
    private readonly signalementsRepository: Repository<Signalement>,
    private readonly usersService: UsersService,
  ) {}

  async signaler(dto: {
    signaleUserId: string;
    auteurId: string;
    motif: string;
  }): Promise<Signalement> {
    if (dto.signaleUserId === dto.auteurId) {
      // On ne se signale pas soi-même (cas bloqué côté serveur).
      throw new Error('Signalement invalide');
    }
    const utilisateurSignale = await this.usersService.findOne(
      dto.signaleUserId,
    );
    const auteur = await this.usersService.findOne(dto.auteurId);
    const signalement = this.signalementsRepository.create({
      utilisateurSignale,
      auteur,
      motif: dto.motif.trim(),
      statut: StatutSignalement.EN_ATTENTE,
    });
    return this.signalementsRepository.save(signalement);
  }

  async enAttente(): Promise<Signalement[]> {
    return this.signalementsRepository.find({
      where: { statut: StatutSignalement.EN_ATTENTE },
      relations: { utilisateurSignale: true, auteur: true },
      order: { creeLe: 'DESC' },
    });
  }

  async tous(): Promise<Signalement[]> {
    return this.signalementsRepository.find({
      relations: { utilisateurSignale: true, auteur: true },
      order: { creeLe: 'DESC' },
    });
  }
}
