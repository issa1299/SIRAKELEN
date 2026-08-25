import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { Demande, StatutDemande } from './demande.entity';
import { AvisDeplacement, StatutAd } from '../ads/avis-deplacement.entity';
import { UsersService } from '../users/users.service';

@Injectable()
export class DemandesService {
  constructor(
    @InjectRepository(Demande)
    private readonly demandesRepository: Repository<Demande>,
    @InjectRepository(AvisDeplacement)
    private readonly adsRepository: Repository<AvisDeplacement>,
    private readonly usersService: UsersService,
  ) {}

  /** Le demandeur envoie une demande pour rejoindre un AD. */
  async envoyer(
    adId: string,
    demandeurId: string,
  ): Promise<Demande> {
    const ad = await this.adsRepository.findOne({
      where: { id: adId },
      relations: { proprietaire: true },
    });
    if (!ad) {
      throw new NotFoundException('AD introuvable');
    }
    if (ad.proprietaire.id === demandeurId) {
      throw new BadRequestException('Cet AD est le tien');
    }
    if (ad.statut !== StatutAd.ACTIF) {
      throw new BadRequestException(
        'Cet AD n’accepte plus de nouvelles demandes',
      );
    }

    const demandeur = await this.usersService.findOne(demandeurId);

    // Pas de double demande.
    const existante = await this.demandesRepository.findOne({
      where: { ad: { id: adId }, demandeur: { id: demandeurId } },
    });
    if (existante) {
      if (existante.statut === StatutDemande.EN_ATTENTE) {
        throw new BadRequestException('Ta demande est déjà en attente');
      }
      // On peut redemander après un refus/annulation.
      existante.statut = StatutDemande.EN_ATTENTE;
      return this.demandesRepository.save(existante);
    }

    const demande = this.demandesRepository.create({
      ad,
      demandeur,
      statut: StatutDemande.EN_ATTENTE,
    });
    return this.demandesRepository.save(demande);
  }

  /** Demandes reçues sur les AD d'un utilisateur. */
  async recues(userId: string) {
    await this.usersService.findOne(userId);
    return this.demandesRepository.find({
      where: { ad: { proprietaire: { id: userId } } },
      relations: { demandeur: true, ad: true },
      order: { creeLe: 'DESC' },
    });
  }

  /** Demandes envoyées par un utilisateur. */
  async envoyees(userId: string) {
    await this.usersService.findOne(userId);
    return this.demandesRepository.find({
      where: { demandeur: { id: userId } },
      relations: { ad: { proprietaire: true }, demandeur: true },
      order: { creeLe: 'DESC' },
    });
  }

  /** Le propriétaire accepte une demande : l'AD passe en finalisation. */
  async accepter(demandeId: string, proprietaireId: string) {
    const demande = await this.demandesRepository.findOne({
      where: { id: demandeId },
      relations: { ad: { proprietaire: true }, demandeur: true },
    });
    if (!demande) {
      throw new NotFoundException('Demande introuvable');
    }
    if (demande.ad.proprietaire.id !== proprietaireId) {
      throw new BadRequestException('Cet AD ne t’appartient pas');
    }
    if (demande.statut !== StatutDemande.EN_ATTENTE) {
      throw new BadRequestException('Cette demande n’est plus en attente');
    }
    if (demande.ad.statut !== StatutAd.ACTIF) {
      throw new BadRequestException(
        'Cet AD n’accepte plus de nouvelles demandes',
      );
    }

    demande.statut = StatutDemande.ACCEPTEE;
    await this.demandesRepository.save(demande);

    // L'AD passe en cours de finalisation.
    demande.ad.statut = StatutAd.EN_COURS_DE_FINALISATION;
    await this.adsRepository.save(demande.ad);

    // Les autres demandes en attente sur ce AD sont refusées automatiquement.
    const autres = await this.demandesRepository.find({
      where: {
        ad: { id: demande.ad.id },
        statut: StatutDemande.EN_ATTENTE,
      },
    });
    for (const autre of autres) {
      autre.statut = StatutDemande.REFUSEE;
      await this.demandesRepository.save(autre);
    }

    return this.demandesRepository.findOne({
      where: { id: demandeId },
      relations: { demandeur: true, ad: true },
    });
  }

  async refuser(demandeId: string, proprietaireId: string) {
    const demande = await this.demandesRepository.findOne({
      where: { id: demandeId },
      relations: { ad: { proprietaire: true } },
    });
    if (!demande) {
      throw new NotFoundException('Demande introuvable');
    }
    if (demande.ad.proprietaire.id !== proprietaireId) {
      throw new BadRequestException('Cet AD ne t’appartient pas');
    }
    if (demande.statut !== StatutDemande.EN_ATTENTE) {
      throw new BadRequestException('Cette demande n’est plus en attente');
    }
    demande.statut = StatutDemande.REFUSEE;
    return this.demandesRepository.save(demande);
  }

  /** Le demandeur annule sa demande (possible tant qu'en attente). */
  async annuler(demandeId: string, demandeurId: string) {
    const demande = await this.demandesRepository.findOne({
      where: { id: demandeId },
      relations: { demandeur: true },
    });
    if (!demande) {
      throw new NotFoundException('Demande introuvable');
    }
    if (demande.demandeur.id !== demandeurId) {
      throw new BadRequestException('Cette demande n’est pas la tienne');
    }
    if (demande.statut !== StatutDemande.EN_ATTENTE) {
      throw new BadRequestException(
        'Seule une demande en attente peut être annulée',
      );
    }
    demande.statut = StatutDemande.ANNULEE;
    return this.demandesRepository.save(demande);
  }

  /** Le propriétaire marque le trajet comme organisé. */
  async marquerOrganise(adId: string, proprietaireId: string) {
    const ad = await this.adsRepository.findOne({
      where: { id: adId },
      relations: { proprietaire: true },
    });
    if (!ad) {
      throw new NotFoundException('AD introuvable');
    }
    if (ad.proprietaire.id !== proprietaireId) {
      throw new BadRequestException('Cet AD ne t’appartient pas');
    }
    if (ad.statut !== StatutAd.EN_COURS_DE_FINALISATION) {
      throw new BadRequestException(
        'Seul un AD en cours de finalisation peut être marqué organisé',
      );
    }
    ad.statut = StatutAd.TRAJET_ORGANISE;
    return this.adsRepository.save(ad);
  }
}
