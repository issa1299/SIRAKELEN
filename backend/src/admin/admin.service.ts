import { Injectable, UnauthorizedException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import { AvisDeplacement, StatutAd } from '../ads/avis-deplacement.entity';
import { Demande, StatutDemande } from '../demandes/demande.entity';
import { Signalement } from '../signalements/signalement.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(AvisDeplacement) private adRepo: Repository<AvisDeplacement>,
    @InjectRepository(Demande) private demandeRepo: Repository<Demande>,
    @InjectRepository(Signalement) private signalementRepo: Repository<Signalement>,
  ) {}

  async login(email: string, motDePasse: string) {
    const user = await this.userRepo.findOne({ where: { email } });
    if (!user || user.motDePasse !== motDePasse || !user.admin) {
      throw new UnauthorizedException('Email ou mot de passe incorrect');
    }
    return {
      id: user.id,
      prenom: user.prenom,
      nom: user.nom,
      email: user.email,
      admin: true,
      token: `admin_${user.id}`,
    };
  }

  async stats() {
    const totalUsers = await this.userRepo.count();
    const totalAds = await this.adRepo.count();
    const adsActifs = await this.adRepo.count({ where: { statut: StatutAd.ACTIF } });
    const totalDemandes = await this.demandeRepo.count();
    const demandesAcceptees = await this.demandeRepo.count({ where: { statut: StatutDemande.ACCEPTEE } });
    const totalSignalements = await this.signalementRepo.count();
    const matchingRate = totalDemandes > 0 ? Math.round((demandesAcceptees / totalDemandes) * 100) : 0;

    return {
      totalUsers,
      totalAds,
      adsActifs,
      totalDemandes,
      demandesAcceptees,
      matchingRate,
      totalSignalements,
    };
  }

  async findAllUsers() {
    return this.userRepo.find({
      order: { creeLe: 'DESC' },
    });
  }

  async findAllAds() {
    return this.adRepo.find({
      relations: { proprietaire: true },
      order: { creeLe: 'DESC' },
    });
  }

  async findAllSignalements() {
    return this.signalementRepo.find({
      relations: { auteur: true, utilisateurSignale: true },
      order: { creeLe: 'DESC' },
    });
  }
}
