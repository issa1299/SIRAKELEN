import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { User, StatutUtilisateur } from '../users/user.entity';
import {
  Notification,
  CibleNotification,
  GroupeNotification,
  StatutNotification,
} from './notification.entity';
import { NotificationToken } from './notification-token.entity';
import { FcmService } from './fcm.service';

export interface CreerNotificationDto {
  titre: string;
  corps: string;
  cible: CibleNotification;
  cibleValeur?: string;
  dateProgramme?: string;
}

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification) private readonly repo: Repository<Notification>,
    @InjectRepository(NotificationToken)
    private readonly tokenRepo: Repository<NotificationToken>,
    @InjectRepository(User) private readonly userRepo: Repository<User>,
    private readonly fcm: FcmService,
  ) {}

  get fcmConfigure(): boolean {
    return this.fcm.configure;
  }

  async creer(dto: CreerNotificationDto, admin: { id: string; prenom: string }) {
    if (!Object.values(CibleNotification).includes(dto.cible)) {
      throw new BadRequestException('Cible invalide');
    }
    if (dto.cible !== CibleNotification.TOUS && !dto.cibleValeur) {
      throw new BadRequestException('Une cible précise est requise');
    }
    const date = dto.dateProgramme ? new Date(dto.dateProgramme) : null;
    if (date && isNaN(date.getTime())) {
      throw new BadRequestException('Date de programmation invalide');
    }
    const programmee = !!date && date.getTime() > Date.now();
    const notification = this.repo.create({
      titre: dto.titre.slice(0, 120),
      corps: dto.corps,
      cible: dto.cible,
      cibleValeur: dto.cibleValeur || null,
      statut: programmee ? StatutNotification.PROGRAMMEE : StatutNotification.BROUILLON,
      dateProgramme: date,
      creePar: admin.id,
      creeParPrenom: admin.prenom,
    });
    await this.repo.save(notification);
    if (!programmee) await this.envoyer(notification.id);
    return this.repo.findOne({ where: { id: notification.id } });
  }

  async findAll() {
    // Traite les notifications programmées dont l'heure est passée (exécution paresseuse).
    const dues = await this.repo.find({
      where: { statut: StatutNotification.PROGRAMMEE },
    });
    for (const n of dues) {
      if (n.dateProgramme && n.dateProgramme.getTime() <= Date.now()) {
        await this.envoyer(n.id);
      }
    }
    return this.repo.find({ order: { creeLe: 'DESC' }, take: 200 });
  }

  /** Notifications publiées, consultables par l'application (historique in-app). */
  async findPubliees(limite = 50) {
    return this.repo.find({
      where: { statut: StatutNotification.ENVOYEE },
      order: { dateEnvoi: 'DESC' },
      take: Math.min(limite, 100),
      select: { id: true, titre: true, corps: true, dateEnvoi: true, creeLe: true },
    });
  }

  private async destinatairesIds(n: Notification): Promise<string[]> {
    const qb = this.userRepo.createQueryBuilder('u').select('u.id');
    if (n.cible === CibleNotification.INDIVIDUEL) {
      const u = await this.userRepo.findOne({ where: { id: n.cibleValeur } });
      return u ? [u.id] : [];
    }
    if (n.cible === CibleNotification.GROUPE) {
      switch (n.cibleValeur) {
        case GroupeNotification.ACTIFS:
          qb.where('u.statut = :s', { s: StatutUtilisateur.ACTIF });
          break;
        case GroupeNotification.SUSPENDUS:
          qb.where('u.statut IN (:...s)', {
            s: [StatutUtilisateur.SUSPENDU, StatutUtilisateur.BANNI],
          });
          break;
        case GroupeNotification.ADMINS:
          qb.where('u.admin = true');
          break;
        case GroupeNotification.VERIFIES:
          qb.where('u.verifie = true');
          break;
        case GroupeNotification.NON_VERIFIES:
          qb.where('u.verifie = false');
          break;
        default:
          return [];
      }
    }
    const users = await qb.getMany();
    return users.map((u) => u.id);
  }

  async envoyer(id: string) {
    const n = await this.repo.findOne({ where: { id } });
    if (!n) throw new NotFoundException('Notification introuvable');

    const ids = await this.destinatairesIds(n);
    const tokens = ids.length
      ? await this.tokenRepo.find({ where: { userId: In(ids), actif: true } })
      : [];

    let envoyes = 0;
    let echecs = 0;
    let resultat: string;
    if (this.fcm.configure) {
      for (const token of tokens) {
        const ok = await this.fcm.envoyer(token.token, n.titre, n.corps);
        if (ok) envoyes += 1;
        else echecs += 1;
      }
      resultat = `FCM : ${envoyes} envoyé(s), ${echecs} échec(s) sur ${tokens.length} token(s) actif(s)`;
    } else {
      resultat = `FCM non configuré : ${ids.length} destinataire(s) ciblé(s), ${tokens.length} token(s), aucun push envoyé`;
    }

    n.destinataires = ids.length;
    n.envoyes = envoyes;
    n.echecs = echecs;
    n.resultat = resultat;
    n.statut = StatutNotification.ENVOYEE;
    n.dateEnvoi = new Date();
    await this.repo.save(n);
    return n;
  }

  async enregistrerToken(dto: {
    userId: string;
    token: string;
    plateforme?: string;
  }) {
    if (!dto.userId || !dto.token) {
      throw new BadRequestException('userId et token requis');
    }
    const existant = await this.tokenRepo.findOne({
      where: { token: dto.token },
    });
    if (existant) {
      existant.userId = dto.userId;
      existant.plateforme = dto.plateforme || 'android';
      existant.actif = true;
      await this.tokenRepo.save(existant);
      return { enregistre: true };
    }
    await this.tokenRepo.save(
      this.tokenRepo.create({
        userId: dto.userId,
        token: dto.token,
        plateforme: dto.plateforme || 'android',
        actif: true,
      }),
    );
    return { enregistre: true };
  }

  async nbEnvoyees(): Promise<number> {
    return this.repo.count({ where: { statut: StatutNotification.ENVOYEE } });
  }
}
