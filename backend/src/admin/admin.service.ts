import {
  Injectable,
  UnauthorizedException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { User, StatutUtilisateur } from '../users/user.entity';
import { AvisDeplacement, StatutAd } from '../ads/avis-deplacement.entity';
import { Demande, StatutDemande } from '../demandes/demande.entity';
import { Signalement, StatutSignalement } from '../signalements/signalement.entity';
import { AdminLog } from './admin-log.entity';
import { AdminAuthService } from './admin-auth.service';
import { AdminRole } from './admin-role.enum';
import { Evenement, TypeEvenement } from '../evenements/evenement.entity';
import { Notification, StatutNotification } from '../notifications/notification.entity';

/** Champs sensibles jamais exposés par l'admin. */
const CHAMPS_SENSIBLES = ['motDePasse', 'codeRecuperation'];

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(AvisDeplacement) private adRepo: Repository<AvisDeplacement>,
    @InjectRepository(Demande) private demandeRepo: Repository<Demande>,
    @InjectRepository(Signalement) private signalementRepo: Repository<Signalement>,
    @InjectRepository(AdminLog) private logRepo: Repository<AdminLog>,
    @InjectRepository(Evenement) private evenementRepo: Repository<Evenement>,
    @InjectRepository(Notification) private notificationRepo: Repository<Notification>,
    private readonly auth: AdminAuthService,
  ) {}

  // ------------------------------------------------------------------
  // Authentification
  // ------------------------------------------------------------------

  async login(email: string, motDePasse: string) {
    const user = await this.userRepo.findOne({ where: { email } });
    if (
      !user ||
      !user.admin ||
      !this.auth.verifierMotDePasse(motDePasse, user.motDePasse)
    ) {
      throw new UnauthorizedException('Email ou mot de passe incorrect');
    }
    /**
     * Amorçage sécurisé : le tout premier compte administrateur de la
     * plateforme devient SUPER_ADMIN s'il n'en existe aucun. Uniquement
     * l'email désigné par ADMIN_SUPER_EMAIL est éligible. Aucun autre
     * utilisateur ne reçoit ce rôle automatiquement.
     */
    let role = (user.adminRole || AdminRole.ADMIN) as AdminRole;
    const emailSuper = (
      process.env.ADMIN_SUPER_EMAIL || 'admin@sirakele.com'
    ).toLowerCase();
    if (
      !user.adminRole &&
      user.email?.toLowerCase() === emailSuper &&
      (await this.userRepo.count({ where: { adminRole: AdminRole.SUPER_ADMIN } })) === 0
    ) {
      user.adminRole = AdminRole.SUPER_ADMIN;
      await this.userRepo.save(user);
      role = AdminRole.SUPER_ADMIN;
    }

    const token = this.auth.creerToken(user.id, role, user.prenom);

    await this.journal(
      user.id,
      user.prenom,
      'CONNEXION_ADMIN',
      'User',
      user.id,
      null,
    );

    return {
      id: user.id,
      prenom: user.prenom,
      nom: user.nom,
      email: user.email,
      admin: true,
      role,
      token,
    };
  }

  // ------------------------------------------------------------------
  // Journal d'activité
  // ------------------------------------------------------------------

  async journal(
    adminId: string,
    adminPrenom: string | null,
    action: string,
    objetType?: string | null,
    objetId?: string | null,
    detail?: string | null,
  ): Promise<void> {
    try {
      await this.logRepo.save(
        this.logRepo.create({
          adminId,
          adminPrenom: adminPrenom ?? null,
          action,
          objetType: objetType ?? null,
          objetId: objetId ?? null,
          detail: detail ?? null,
        }),
      );
    } catch {
      // La journalisation ne doit jamais faire échouer l'action principale.
    }
  }

  async findLogs(limite = 100): Promise<AdminLog[]> {
    return this.logRepo.find({
      order: { creeLe: 'DESC' },
      take: Math.min(limite, 500),
    });
  }

  // ------------------------------------------------------------------
  // Statistiques réelles
  // ------------------------------------------------------------------

  async stats() {
    const [
      totalUsers,
      usersActifs,
      nouveaux30j,
      totalAds,
      adsActifs,
      totalTrajetsOrganises,
      totalDemandes,
      demandesAcceptees,
      totalSignalements,
      signalementsEnAttente,
      totalMessages,
      notificationsEnvoyees,
      telechargementsApk,
      visitesSite,
    ] = await Promise.all([
      this.userRepo.count(),
      this.userRepo.count({ where: { statut: StatutUtilisateur.ACTIF } }),
      this.userRepo
        .createQueryBuilder('u')
        .where('u."creeLe" >= :date', {
          date: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        })
        .getCount(),
      this.adRepo.count(),
      this.adRepo.count({ where: { statut: StatutAd.ACTIF } }),
      this.adRepo.count({ where: { statut: StatutAd.TRAJET_ORGANISE } }),
      this.demandeRepo.count(),
      this.demandeRepo.count({ where: { statut: StatutDemande.ACCEPTEE } }),
      this.signalementRepo.count(),
      this.signalementRepo.count({
        where: { statut: StatutSignalement.EN_ATTENTE },
      }),
      // Le total des messages est compté via une requête légère (pas de chargement).
      this.demandeRepo.manager.query(
        'SELECT COUNT(*)::int AS total FROM messages',
      ),
      this.notificationRepo.count({
        where: { statut: StatutNotification.ENVOYEE },
      }),
      this.evenementRepo.count({
        where: { type: TypeEvenement.TELECHARGEMENT_APK },
      }),
      this.evenementRepo.count({ where: { type: TypeEvenement.VISITE_SITE } }),
    ]);

    const nbMessages = Array.isArray(totalMessages)
      ? (totalMessages[0]?.total ?? 0)
      : 0;

    return {
      totalUsers,
      usersActifs,
      nouveauxInscrits30j: nouveaux30j,
      totalAnnonces: totalAds,
      annoncesActives: adsActifs,
      totalTrajets: totalTrajetsOrganises,
      totalSignalements,
      signalementsEnAttente,
      totalDemandes,
      demandesAcceptees,
      matchingRate:
        totalDemandes > 0 ? Math.round((demandesAcceptees / totalDemandes) * 100) : 0,
      totalMessages: nbMessages,
      notificationsEnvoyees,
      telechargementsApk,
      visitesSite,
    };
  }

  /** Activité récente : derniers incidents/utilisateurs/annonces. */
  async activiteRecente() {
    const [utilisateurs, annonces, signalements, logs] = await Promise.all([
      this.userRepo.find({
        select: ['id', 'prenom', 'nom', 'creeLe'] as any,
        order: { creeLe: 'DESC' },
        take: 5,
      }),
      this.adRepo.find({
        select: ['id', 'depart', 'destination', 'statut', 'creeLe'] as any,
        order: { creeLe: 'DESC' },
        take: 5,
      }),
      this.signalementRepo.find({
        relations: { auteur: true },
        order: { creeLe: 'DESC' },
        take: 5,
      }),
      this.logRepo.find({ order: { creeLe: 'DESC' }, take: 10 }),
    ]);
    return { utilisateurs, annonces, signalements, logs };
  }

  // ------------------------------------------------------------------
  // Utilisateurs
  // ------------------------------------------------------------------

  private nettoyer<T extends Record<string, any>>(objet: T): Partial<T> {
    const copie: any = { ...objet };
    for (const c of CHAMPS_SENSIBLES) delete copie[c];
    return copie;
  }

  async findAllUsers(
    filtres: { q?: string; statut?: StatutUtilisateur; admin?: boolean } = {},
  ) {
    const qb = this.userRepo.createQueryBuilder('u');
    if (filtres.q) {
      const terme = `%${filtres.q.replace(/[%_]/g, ' ')}%`;
      qb.andWhere(
        '(u.prenom ILIKE :q OR u.nom ILIKE :q OR u.telephone ILIKE :q OR u.email ILIKE :q)',
        { q: terme },
      );
    }
    if (filtres.statut) qb.andWhere('u.statut = :statut', { statut: filtres.statut });
    if (filtres.admin !== undefined) {
      qb.andWhere('u.admin = :admin', { admin: filtres.admin });
    }
    const users = await qb.orderBy('u.creeLe', 'DESC').take(500).getMany();
    return users.map((u) => this.nettoyer(u));
  }

  async findUser(id: string) {
    const u = await this.userRepo.findOne({ where: { id } });
    if (!u) throw new NotFoundException('Utilisateur introuvable');
    return this.nettoyer(u);
  }

  /** Modifie les champs autorisés (pas de mot de passe ni de rôle ici). */
  async updateUser(
    id: string,
    dto: { prenom?: string; nom?: string; quartier?: string; telephone?: string },
  ) {
    const u = await this.userRepo.findOne({ where: { id } });
    if (!u) throw new NotFoundException('Utilisateur introuvable');
    for (const c of ['prenom', 'nom', 'quartier', 'telephone'] as const) {
      if (dto[c] !== undefined) (u as any)[c] = dto[c];
    }
    await this.userRepo.save(u);
    return this.nettoyer(u);
  }

  async suspendreUser(
    id: string,
    statut: StatutUtilisateur,
    motif: string,
    admin: { id: string; prenom: string },
  ) {
    if (![StatutUtilisateur.SUSPENDU, StatutUtilisateur.BANNI].includes(statut)) {
      throw new BadRequestException('Statut de suspension invalide');
    }
    const u = await this.userRepo.findOne({ where: { id } });
    if (!u) throw new NotFoundException('Utilisateur introuvable');
    if (u.admin) throw new BadRequestException('Un compte administrateur ne peut pas être suspendu ici');
    u.statut = statut;
    u.motifSuspension = motif?.trim() || null;
    u.suspenduLe = new Date();
    await this.userRepo.save(u);
    await this.journal(
      admin.id,
      admin.prenom,
      statut === StatutUtilisateur.BANNI ? 'UTILISATEUR_BANNI' : 'UTILISATEUR_SUSPENDU',
      'User',
      id,
      motif,
    );
    return this.nettoyer(u);
  }

  /** Suppression seulement si le compte n'est lié à aucune donnée métier. */
  async supprimerUser(id: string, admin: { id: string; prenom: string }) {
    const u = await this.userRepo.findOne({ where: { id } });
    if (!u) throw new NotFoundException('Utilisateur introuvable');
    if (u.admin) {
      throw new BadRequestException('Un compte administrateur ne peut pas être supprimé');
    }
    const [ads, demandes, signauxAuteur, signauxCible] = await Promise.all([
      this.adRepo.count({ where: { proprietaire: { id } } }),
      this.demandeRepo.count({ where: { demandeur: { id } } }),
      this.signalementRepo.count({ where: { auteur: { id } } }),
      this.signalementRepo.count({ where: { utilisateurSignale: { id } } }),
    ]);
    if (ads + demandes + signauxAuteur + signauxCible > 0) {
      throw new BadRequestException(
        'Compte lié à des annonces, demandes ou signalements : utilisez la suspension pour préserver l’historique.',
      );
    }
    await this.userRepo.remove(u);
    await this.journal(admin.id, admin.prenom, 'UTILISATEUR_SUPPRIME', 'User', id, null);
    return { supprime: true };
  }

  async reactiverUser(id: string, admin: { id: string; prenom: string }) {
    const u = await this.userRepo.findOne({ where: { id } });
    if (!u) throw new NotFoundException('Utilisateur introuvable');
    u.statut = StatutUtilisateur.ACTIF;
    u.motifSuspension = null;
    u.suspenduLe = null;
    await this.userRepo.save(u);
    await this.journal(admin.id, admin.prenom, 'UTILISATEUR_REACTIVE', 'User', id, null);
    return this.nettoyer(u);
  }

  /** Signalements liés à un utilisateur. */
  async signalementsUtilisateur(id: string) {
    return this.signalementRepo.find({
      where: { utilisateurSignale: { id } },
      relations: { auteur: true, ad: true },
      order: { creeLe: 'DESC' },
    });
  }

  // ------------------------------------------------------------------
  // Annonces / trajets
  // ------------------------------------------------------------------

  async findAllAds(
    filtres: { q?: string; statut?: StatutAd } = {},
  ) {
    const qb = this.adRepo
      .createQueryBuilder('ad')
      .leftJoinAndSelect('ad.proprietaire', 'proprietaire');
    if (filtres.q) {
      const terme = `%${filtres.q.replace(/[%_]/g, ' ')}%`;
      qb.andWhere('(ad.depart ILIKE :q OR ad.destination ILIKE :q)', { q: terme });
    }
    if (filtres.statut) qb.andWhere('ad.statut = :statut', { statut: filtres.statut });
    const ads = await qb.orderBy('ad.creeLe', 'DESC').take(500).getMany();
    return ads.map((a) => ({
      ...a,
      proprietaire: a.proprietaire ? this.nettoyer(a.proprietaire as any) : null,
    }));
  }

  async modifierStatutAd(
    id: string,
    statut: StatutAd,
    admin: { id: string; prenom: string },
  ) {
    const ad = await this.adRepo.findOne({ where: { id } });
    if (!ad) throw new NotFoundException('Annonce introuvable');
    ad.statut = statut;
    await this.adRepo.save(ad);
    await this.journal(admin.id, admin.prenom, 'ANNONCE_STATUT_MODIFIE', 'AvisDeplacement', id, statut);
    return ad;
  }

  /** Modifie les champs autorisés d'une annonce. */
  async modifierAd(
    id: string,
    dto: { depart?: string; destination?: string; dateDeplacement?: string; heureDepart?: string },
    admin: { id: string; prenom: string },
  ) {
    const ad = await this.adRepo.findOne({ where: { id } });
    if (!ad) throw new NotFoundException('Annonce introuvable');
    for (const c of ['depart', 'destination', 'dateDeplacement', 'heureDepart'] as const) {
      if (dto[c] !== undefined) (ad as any)[c] = dto[c];
    }
    await this.adRepo.save(ad);
    await this.journal(admin.id, admin.prenom, 'ANNONCE_MODIFIEE', 'AvisDeplacement', id, JSON.stringify(dto));
    return ad;
  }

  /** Suppression définitive d'une annonce (confirmation exigée côté client). */
  async supprimerAd(id: string, admin: { id: string; prenom: string }) {
    const ad = await this.adRepo.findOne({ where: { id } });
    if (!ad) throw new NotFoundException('Annonce introuvable');
    await this.adRepo.remove(ad);
    await this.journal(admin.id, admin.prenom, 'ANNONCE_SUPPRIMEE', 'AvisDeplacement', id, null);
    return { message: 'Annonce supprimée' };
  }

  // ------------------------------------------------------------------
  // Signalements : traitement réel
  // ------------------------------------------------------------------

  async findAllSignalements(
    filtres: { statut?: StatutSignalement } = {},
  ) {
    const qb = this.signalementRepo
      .createQueryBuilder('s')
      .leftJoinAndSelect('s.auteur', 'auteur')
      .leftJoinAndSelect('s.utilisateurSignale', 'utilisateurSignale')
      .leftJoinAndSelect('s.ad', 'ad');
    if (filtres.statut) qb.andWhere('s.statut = :statut', { statut: filtres.statut });
    const signaux = await qb.orderBy('s.creeLe', 'DESC').take(500).getMany();
    return signaux.map((s) => ({
      ...s,
      auteur: s.auteur ? this.nettoyer(s.auteur as any) : null,
      utilisateurSignale: s.utilisateurSignale
        ? this.nettoyer(s.utilisateurSignale as any)
        : null,
    }));
  }

  /** Traite ou rejette un signalement (historique conservé dans admin_logs). */
  async traiterSignalement(
    id: string,
    decision: 'traite' | 'rejete',
    detail: string,
    admin: { id: string; prenom: string },
  ) {
    const s = await this.signalementRepo.findOne({ where: { id } });
    if (!s) throw new NotFoundException('Signalement introuvable');
    s.statut = StatutSignalement.TRAITE;
    await this.signalementRepo.save(s);
    await this.journal(
      admin.id,
      admin.prenom,
      decision === 'rejete' ? 'SIGNALEMENT_REJETE' : 'SIGNALEMENT_TRAITE',
      'Signalement',
      id,
      detail,
    );
    return s;
  }

  // ------------------------------------------------------------------
  // Demandes (modération)
  // ------------------------------------------------------------------

  async findAllDemandes() {
    return this.demandeRepo.find({
      relations: { ad: true, demandeur: true },
      order: { creeLe: 'DESC' },
      take: 500,
    });
  }

  // ------------------------------------------------------------------
  // Profil / mot de passe admin
  // ------------------------------------------------------------------

  async updateProfil(id: string, prenom?: string, nom?: string) {
    const user = await this.userRepo.findOne({ where: { id } });
    if (!user || !user.admin) {
      throw new UnauthorizedException('Compte introuvable');
    }
    if (prenom?.trim()) user.prenom = prenom.trim();
    if (nom?.trim()) user.nom = nom.trim();
    const sauve = await this.userRepo.save(user);
    return this.nettoyer(sauve);
  }

  async changerMotDePasse(id: string, ancien: string, nouveau: string) {
    const user = await this.userRepo.findOne({ where: { id } });
    if (!user || !user.admin) {
      throw new UnauthorizedException('Compte introuvable');
    }
    if (!this.auth.verifierMotDePasse(ancien, user.motDePasse)) {
      throw new UnauthorizedException('Ancien mot de passe incorrect');
    }
    if (!nouveau || nouveau.length < 8) {
      throw new BadRequestException(
        'Le nouveau mot de passe doit contenir au moins 8 caractères',
      );
    }
    // Hachage scrypt : plus jamais de mot de passe en clair.
    user.motDePasse = this.auth.hacherMotDePasse(nouveau);
    await this.userRepo.save(user);
    await this.journal(user.id, user.prenom, 'MOT_DE_PASSE_ADMIN_MODIFIE', 'User', user.id, null);
    return { message: 'Mot de passe modifié et sécurisé' };
  }

  // ------------------------------------------------------------------
  // Gestion des administrateurs (super admin)
  // ------------------------------------------------------------------

  async promouvoirAdmin(id: string, role: AdminRole, admin: { id: string; prenom: string }) {
    const u = await this.userRepo.findOne({ where: { id } });
    if (!u) throw new NotFoundException('Utilisateur introuvable');
    u.admin = true;
    u.adminRole = role;
    await this.userRepo.save(u);
    await this.journal(admin.id, admin.prenom, 'ADMIN_PROMU', 'User', id, role);
    return this.nettoyer(u);
  }

  async revoquerAdmin(id: string, admin: { id: string; prenom: string }) {
    const u = await this.userRepo.findOne({ where: { id } });
    if (!u) throw new NotFoundException('Utilisateur introuvable');
    u.admin = false;
    u.adminRole = null;
    await this.userRepo.save(u);
    await this.journal(admin.id, admin.prenom, 'ADMIN_REVOQUE', 'User', id, null);
    return this.nettoyer(u);
  }

  async findAllAdmins() {
    const admins = await this.userRepo.find({
      where: { admin: true },
      order: { creeLe: 'DESC' },
    });
    return admins.map((a) => this.nettoyer(a));
  }
}
