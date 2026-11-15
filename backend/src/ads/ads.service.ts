import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Not, In } from 'typeorm';
import { AvisDeplacement, RoleAd, StatutAd } from './avis-deplacement.entity';
import { Demande, StatutDemande } from '../demandes/demande.entity';
import { UsersService } from '../users/users.service';
import { CreateAdDto } from './dto/create-ad.dto';
import { ListerAdsDto } from './dto/lister-ads.dto';
import {
  evaluerCompatibilite,
  prefiltrageRapide,
  MATCHING_CONFIG,
  NiveauCompatibilite,
} from './matching';
import {
  AdEntite,
  AdDeBase,
  LigneParcourir,
  CODE_ACCES_REFUSE,
  MESSAGE_ACCES_REFUSE,
  MAX_LIGNES_PARCOURIR,
  adVisible,
  badgeCompatible,
  comparerDate,
  comparerPertinence,
  construireLigne,
  dateDuJour,
  monAdActif,
  peutParcourir,
  zoneCorrespond,
} from './parcourir';

@Injectable()
export class AdsService {
  constructor(
    @InjectRepository(AvisDeplacement)
    private readonly adsRepository: Repository<AvisDeplacement>,
    private readonly usersService: UsersService,
  ) {}

  async creer(dto: CreateAdDto): Promise<AvisDeplacement> {
    // La date du déplacement ne peut pas être dans le passé.
    const aujourdhui = new Date().toISOString().slice(0, 10);
    if (dto.dateDeplacement < aujourdhui) {
      throw new BadRequestException(
        'La date du déplacement ne peut pas être dans le passé',
      );
    }

    // Champs propres au conducteur.
    if (dto.role === RoleAd.CONDUCTEUR) {
      if (!dto.moyenTransport) {
        throw new BadRequestException(
          'Le moyen de transport est obligatoire pour un conducteur',
        );
      }
      if (!dto.placesDisponibles) {
        throw new BadRequestException(
          'Le nombre de places est obligatoire pour un conducteur',
        );
      }
    }
    // Un passager ne propose ni transport ni places.
    if (dto.role === RoleAd.PASSAGER) {
      dto.moyenTransport = undefined;
      dto.placesDisponibles = undefined;
    }

    // Un seul AD actif à la fois par rôle (règle MVP).
    const existants = await this.adsRepository.find({
      where: {
        proprietaire: { id: dto.userId },
        role: dto.role,
        statut: In([StatutAd.ACTIF, StatutAd.EN_COURS_DE_FINALISATION]),
      },
    });
    if (existants.length > 0) {
      throw new BadRequestException(
        dto.role === RoleAd.CONDUCTEUR
          ? 'Tu as déjà un AD conducteur actif. Modifie-le ou annule-le d’abord.'
          : 'Tu as déjà un AD passager actif. Modifie-le ou annule-le d’abord.',
      );
    }

    const user = await this.usersService.findOne(dto.userId);
    const ad = this.adsRepository.create({
      proprietaire: user,
      role: dto.role,
      depart: dto.depart.trim(),
      departLat: dto.departLat ?? null,
      departLng: dto.departLng ?? null,
      destination: dto.destination.trim(),
      arriveeLat: dto.arriveeLat ?? null,
      arriveeLng: dto.arriveeLng ?? null,
      dateDeplacement: dto.dateDeplacement,
      heureDepart: dto.heureDepart,
      moyenTransport: dto.moyenTransport,
      placesDisponibles: dto.placesDisponibles,
      statut: StatutAd.ACTIF,
    });
    return this.adsRepository.save(ad);
  }

  async mesAds(userId: string): Promise<AvisDeplacement[]> {
    await this.usersService.findOne(userId);
    return this.adsRepository.find({
      where: { proprietaire: { id: userId } },
      order: { creeLe: 'DESC' },
    });
  }

  async compatibilites(
    userId: string,
  ): Promise<
    Array<{
      adId: string;
      monAdId: string;
      nom: string;
      verifie: boolean;
      role: string;
      depart: string;
      destination: string;
      date: string;
      heure: string;
      places: number | null;
      niveau: NiveauCompatibilite;
      scoreFinal: number;
      scoreDirection: number;
      scoreRecouvrement: number;
      ecartMinutes: number | null;
      distDepartKm: number | null;
      distArriveeKm: number | null;
    }>
  > {
    const mesAds = await this.adsRepository.find({
      where: { proprietaire: { id: userId }, statut: StatutAd.ACTIF },
    });
    if (mesAds.length === 0) return [];

    // Prefiltrage cote base : memes dates, statut ACTIF (performances :
    // on ne charge jamais tout l'historique, seulement les candidats du jour).
    const dates = [...new Set(mesAds.map((a) => a.dateDeplacement))];
    const autresAds = await this.adsRepository.find({
      where: { statut: StatutAd.ACTIF, dateDeplacement: In(dates) },
      relations: { proprietaire: true },
    });

    const resultats: Array<{
      adId: string;
      monAdId: string;
      userId: string;
      nom: string;
      verifie: boolean;
      role: string;
      depart: string;
      destination: string;
      departLat: number | null;
      departLng: number | null;
      arriveeLat: number | null;
      arriveeLng: number | null;
      monDepartLat: number | null;
      monDepartLng: number | null;
      monArriveeLat: number | null;
      monArriveeLng: number | null;
      date: string;
      heure: string;
      places: number | null;
      niveau: NiveauCompatibilite;
      scoreFinal: number;
      scoreDirection: number;
      scoreRecouvrement: number;
      ecartMinutes: number | null;
      distDepartKm: number | null;
      distArriveeKm: number | null;
    }> = [];

    for (const monAd of mesAds) {
      const monPoint = {
        departLat: monAd.departLat,
        departLng: monAd.departLng,
        arriveeLat: monAd.arriveeLat,
        arriveeLng: monAd.arriveeLng,
        depart: monAd.depart,
        destination: monAd.destination,
        heureDepart: monAd.heureDepart,
      };
      let evalues = 0;
      for (const autre of autresAds) {
        if (autre.proprietaire.id === userId) continue;
        if (autre.role === monAd.role) continue;
        if (autre.dateDeplacement !== monAd.dateDeplacement) continue;
        if (evalues >= MATCHING_CONFIG.MAX_CANDIDATS) break;

        const candPoint = {
          departLat: autre.departLat,
          departLng: autre.departLng,
          arriveeLat: autre.arriveeLat,
          arriveeLng: autre.arriveeLng,
          depart: autre.depart,
          destination: autre.destination,
          heureDepart: autre.heureDepart,
        };
        // ETAPE 0 : prefiltrage rapide (bbox + horaire), sans trigonometrie.
        if (!prefiltrageRapide(monPoint, candPoint)) continue;
        evalues++;

        const resultat = evaluerCompatibilite(monPoint, candPoint);

        if (!resultat.niveau) continue;

        resultats.push({
          adId: autre.id,
          monAdId: monAd.id,
          userId: autre.proprietaire.id,
          nom: `${autre.proprietaire.prenom} ${autre.proprietaire.nom.charAt(0).toUpperCase()}.`,
          verifie: autre.proprietaire.verifie,
          role: autre.role,
          depart: autre.depart,
          destination: autre.destination,
          departLat: autre.departLat,
          departLng: autre.departLng,
          arriveeLat: autre.arriveeLat,
          arriveeLng: autre.arriveeLng,
          monDepartLat: monAd.departLat,
          monDepartLng: monAd.departLng,
          monArriveeLat: monAd.arriveeLat,
          monArriveeLng: monAd.arriveeLng,
          date: autre.dateDeplacement,
          heure: autre.heureDepart,
          places: autre.placesDisponibles,
          niveau: resultat.niveau,
          scoreFinal: Math.round(resultat.scoreFinal * 10) / 10,
          scoreDirection: Math.round(resultat.scoreDirection),
          scoreRecouvrement: Math.round(resultat.scoreRecouvrement),
          ecartMinutes: resultat.ecartMinutes,
          distDepartKm:
            resultat.distDepartKm == null
              ? null
              : Math.round(resultat.distDepartKm * 100) / 100,
          distArriveeKm:
            resultat.distArriveeKm == null
              ? null
              : Math.round(resultat.distArriveeKm * 100) / 100,
        });
      }
    }

    const ordre = { fort: 0, moyen: 1, faible: 2 };
    return resultats.sort(
      (a, b) => ordre[a.niveau] - ordre[b.niveau] || b.scoreFinal - a.scoreFinal,
    );
  }

  /**
   * Parcourir tous les AD actifs — en complement (et non en remplacement) de
   * l'algorithme de matching. Verification d'acces cote serveur : un AD actif
   * non expire est obligatoire (sinon 403 AD_ACTIF_REQUIS).
   */
  async parcourir(
    userId: string,
    q: ListerAdsDto,
  ): Promise<{
    items: LigneParcourir[];
    page: number;
    limite: number;
    total: number;
    totalPages: number;
  }> {
    const maintenant = new Date();

    // Utilisateur : ses AD. (findAll pour valider l'existence implicite.)
    const mesAds = await this.adsRepository.find({
      where: { proprietaire: { id: userId } },
      order: { creeLe: 'DESC' },
    });

    // REGLE D'ACCES CRITIQUE — cote serveur.
    if (!peutParcourir(mesAds as AdDeBase[], maintenant)) {
      throw new ForbiddenException({
        statusCode: 403,
        code: CODE_ACCES_REFUSE,
        message: MESSAGE_ACCES_REFUSE,
      });
    }
    const monAd = monAdActif(mesAds as AdDeBase[], maintenant) as AdEntite;

    // Prefiltrage cote base : actifs, a venir, places restantes.
    const aujourdhui = dateDuJour(maintenant);
    const qb = this.adsRepository
      .createQueryBuilder('ad')
      .leftJoinAndSelect('ad.proprietaire', 'proprietaire')
      .where('ad.statut = :statut', { statut: StatutAd.ACTIF })
      .andWhere('ad.dateDeplacement >= :aujourdhui', { aujourdhui })
      .andWhere('(ad.placesDisponibles IS NULL OR ad.placesDisponibles > 0)');

    // Filtre 1 : date / plage horaire.
    const dateEff = q.date ?? (q.elargir ? undefined : monAd.dateDeplacement);
    if (dateEff) {
      qb.andWhere('ad.dateDeplacement = :date', { date: dateEff });
    }
    if (q.heureDebut) {
      qb.andWhere('ad.heureDepart >= :hdeb', { hdeb: q.heureDebut });
    }
    if (q.heureFin) {
      qb.andWhere('ad.heureDepart <= :hfin', { hfin: q.heureFin });
    }

    // Filtre 4 : type de transport (insensible a la casse).
    if (q.transport) {
      const t = q.transport.replace(/[%_]/g, ' ').trim();
      if (t) {
        qb.andWhere('ad.moyenTransport ILIKE :transport', {
          transport: `%${t}%`,
        });
      }
    }

    const candidats = await qb
      .orderBy('ad.dateDeplacement', 'ASC')
      .addOrderBy('ad.heureDepart', 'ASC')
      .take(MAX_LIGNES_PARCOURIR)
      .getMany();

    // Filtres JS : zones (insensible aux accents + jetons), jamais le mien.
    const zoneDep =
      q.zoneDepart ?? (q.elargir ? undefined : monAd.depart);
    const zoneArr =
      q.zoneArrivee ?? (q.elargir ? undefined : monAd.destination);

    const lignes = candidats
      .filter((ad) => {
        const a = ad as unknown as AdEntite;
        if (a.proprietaire?.id === userId) return false;
        if (zoneDep && !zoneCorrespond(a.depart ?? '', zoneDep)) return false;
        if (zoneArr && !zoneCorrespond(a.destination ?? '', zoneArr)) return false;
        return adVisible(a, userId, maintenant);
      })
      .map((ad) => {
        const a = ad as unknown as AdEntite;
        return construireLigne(monAd, a, {
          id: a.proprietaire?.id ?? '',
          prenom: a.proprietaire?.prenom ?? '',
          nom: a.proprietaire?.nom ?? '',
          verifie: a.proprietaire?.verifie ?? false,
          photoUrl: a.proprietaire?.photoUrl ?? null,
        });
      });

    // Tri.
    if (q.tri === 'date') {
      lignes.sort(comparerDate);
    } else {
      lignes.sort(comparerPertinence);
    }

    const page = q.page ?? 1;
    const limite = q.limite ?? 20;
    const total = lignes.length;
    const items = lignes.slice((page - 1) * limite, page * limite);

    return {
      items,
      page,
      limite,
      total,
      totalPages: Math.max(1, Math.ceil(total / limite)),
    };
  }

  /** Trajets publics d'un utilisateur (pour le profil vu par un autre). */
  async trajetsPublics(userId: string) {
    await this.usersService.findOne(userId);
    const ads = await this.adsRepository.find({
      where: { proprietaire: { id: userId }, statut: StatutAd.ACTIF },
    });
    return ads.map((a) => ({
      id: a.id,
      role: a.role,
      depart: a.depart,
      destination: a.destination,
      dateDeplacement: a.dateDeplacement,
      heureDepart: a.heureDepart,
      placesDisponibles: a.placesDisponibles,
    }));
  }

  async annuler(adId: string, userId: string): Promise<AvisDeplacement> {
    const ad = await this.adsRepository.findOne({
      where: { id: adId },
      relations: { proprietaire: true },
    });
    if (!ad) {
      throw new NotFoundException('AD introuvable');
    }
    if (ad.proprietaire.id !== userId) {
      throw new BadRequestException('Cet AD ne vous appartient pas');
    }
    if (ad.statut === StatutAd.TRAJET_ORGANISE) {
      throw new BadRequestException(
        'Un trajet organisé ne peut plus être annulé',
      );
    }
    ad.statut = StatutAd.ANNULE;
    const sauve = await this.adsRepository.save(ad);
    // Purge : les demandes en attente sur un AD annule deviennent invalides.
    await this.adsRepository.manager
      .getRepository(Demande)
      .update(
        { ad: { id: adId }, statut: StatutDemande.EN_ATTENTE },
        { statut: StatutDemande.ANNULEE },
      )
      .catch(() => null);
    return sauve;
  }
}
