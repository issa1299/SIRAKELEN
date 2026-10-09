import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message } from './message.entity';
import { Demande, StatutDemande } from '../demandes/demande.entity';
import { UsersService } from '../users/users.service';

@Injectable()
export class MessagesService {
  constructor(
    @InjectRepository(Message)
    private readonly messagesRepository: Repository<Message>,
    @InjectRepository(Demande)
    private readonly demandesRepository: Repository<Demande>,
    private readonly usersService: UsersService,
  ) {}

  /** Verifie que l'utilisateur est partenaire de la demande et qu'elle est discutable. */
  private async demandeDiscutable(
    demandeId: string,
    userId: string,
  ): Promise<Demande> {
    const demande = await this.demandesRepository.findOne({
      where: { id: demandeId },
      relations: { ad: { proprietaire: true }, demandeur: true },
    });
    if (!demande) {
      throw new NotFoundException('Discussion introuvable');
    }
    const estPartenaire =
      demande.demandeur.id === userId ||
      demande.ad.proprietaire.id === userId;
    if (!estPartenaire) {
      throw new BadRequestException('Discussion privée');
    }
    if (
      demande.statut !== StatutDemande.EN_ATTENTE &&
      demande.statut !== StatutDemande.ACCEPTEE
    ) {
      throw new BadRequestException('Discussion clôturée');
    }
    return demande;
  }

  async envoyer(
    demandeId: string,
    auteurId: string,
    contenu: string,
  ): Promise<Message> {
    const texte = (contenu || '').trim();
    if (!texte) {
      throw new BadRequestException('Message vide');
    }
    if (texte.length > 500) {
      throw new BadRequestException('Message trop long (500 max)');
    }
    const demande = await this.demandeDiscutable(demandeId, auteurId);
    const auteur = await this.usersService.findOne(auteurId);
    const message = this.messagesRepository.create({
      demande,
      auteur,
      contenu: texte,
    });
    return this.messagesRepository.save(message);
  }

  async conversation(demandeId: string, userId: string) {
    await this.demandeDiscutable(demandeId, userId);
    const messages = await this.messagesRepository.find({
      where: { demande: { id: demandeId } },
      relations: { auteur: true },
      order: { creeLe: 'ASC' },
    });
    return messages.map((m) => ({
      id: m.id,
      contenu: m.contenu,
      creeLe: m.creeLe,
      auteurId: m.auteur.id,
      auteurPrenom: m.auteur.prenom,
    }));
  }
}
