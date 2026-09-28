import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository, DataSource } from 'typeorm';
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
    private readonly dataSource: DataSource,
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

  /** Le propriétaire accepte une demande : premier accord valide = RESERVATION.
   * Transaction + verrou pessimiste : deux acceptations simultanees ne peuvent
   * pas reserver le meme AD. Les demandes devenues invalides sont purgees. */
  async accepter(demandeId: string, proprietaireId: string) {
    return this.dataSource.transaction(async (manager) => {
      const demandesRepo = manager.getRepository(Demande);
      const adsRepo = manager.getRepository(AvisDeplacement);

      // Verrou sur l'AD pour eviter deux accords simultanes.
      const adVerrouille = await adsRepo.findOne({
        where: { id: (await demandesRepo.findOne({
          where: { id: demandeId },
          relations: { ad: true },
        }))?.ad.id },
        lock: { mode: 'pessimistic_write' },
      });

      const demande = await demandesRepo.findOne({
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
      // Re-verification sous verrou : premier accord gagne.
      const adFrais = adVerrouille ?? demande.ad;
      if (adFrais.statut !== StatutAd.ACTIF) {
        throw new BadRequestException('Ce trajet est déjà réservé');
      }

      demande.statut = StatutDemande.ACCEPTEE;
      await demandesRepo.save(demande);

      // Reservation de l'AD proprietaire (verrouille).
      adFrais.statut = StatutAd.EN_COURS_DE_FINALISATION;
      await adsRepo.save(adFrais);

      // Reservation symetrique : l'AD du demandeur (role oppose, meme date)
      // est lui aussi verrouille pour eviter les doubles reservations.
      const adsDemandeur = await adsRepo.find({
        where: {
          proprietaire: { id: demande.demandeur.id },
          statut: StatutAd.ACTIF,
          dateDeplacement: adFrais.dateDeplacement,
        },
      });
      for (const adD of adsDemandeur) {
        if (adD.role !== adFrais.role) {
          adD.statut = StatutAd.EN_COURS_DE_FINALISATION;
          await adsRepo.save(adD);
        }
      }
      const idsAdsDemandeur = adsDemandeur.map((a) => a.id);

      // Purge 1 : autres demandes en attente SUR cet AD -> refusees.
      await demandesRepo
        .createQueryBuilder()
        .update(Demande)
        .set({ statut: StatutDemande.REFUSEE })
        .where('statut = :s', { s: StatutDemande.EN_ATTENTE })
        .andWhere('adId = :adId', { adId: adFrais.id })
        .andWhere('id != :id', { id: demande.id })
        .execute();

      // Purge 2 : autres demandes ENVOYEES par le demandeur (ailleurs) -> annulees.
      await demandesRepo
        .createQueryBuilder()
        .update(Demande)
        .set({ statut: StatutDemande.ANNULEE })
        .where('statut = :s', { s: StatutDemande.EN_ATTENTE })
        .andWhere('demandeurId = :dId', { dId: demande.demandeur.id })
        .andWhere('id != :id', { id: demande.id })
        .execute();

      // Purge 3 : demandes RECUES sur les AD du demandeur (devenus reserves) -> refusees.
      if (idsAdsDemandeur.length > 0) {
        await demandesRepo
          .createQueryBuilder()
          .update(Demande)
          .set({ statut: StatutDemande.REFUSEE })
          .where('statut = :s', { s: StatutDemande.EN_ATTENTE })
          .andWhere('adId IN (:...ids)', { ids: idsAdsDemandeur })
          .execute();
      }

      return demandesRepo.findOne({
        where: { id: demandeId },
        relations: { demandeur: true, ad: true },
      });
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

  /** Le propriétaire marque le trajet comme organisé (final, immutable). */
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
    const sauve = await this.adsRepository.save(ad);
    // Purge : plus aucune demande en attente ne doit subsister sur un trajet clos.
    await this.demandesRepository
      .createQueryBuilder()
      .update(Demande)
      .set({ statut: StatutDemande.ANNULEE })
      .where('statut = :s', { s: StatutDemande.EN_ATTENTE })
      .andWhere('adId = :adId', { adId })
      .execute()
      .catch(() => null);
    return sauve;
  }
}
