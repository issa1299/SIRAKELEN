import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from '../users/user.entity';

export enum RoleAd {
  CONDUCTEUR = 'conducteur',
  PASSAGER = 'passager',
}

/**
 * Etats precis d'un AD.
 * - ACTIF : visible dans le matching, accepte de nouvelles demandes.
 * - EN_COURS_DE_FINALISATION : RESERVE par un premier accord valide.
 *   Verrouille : n'accepte plus de nouvelles demandes, exclu du matching.
 * - TRAJET_ORGANISE : trajet confirme (final, immutable).
 * - ANNULE : retire du matching, demandes en attente invalidees.
 */
export enum StatutAd {
  ACTIF = 'actif',
  EN_COURS_DE_FINALISATION = 'en_cours_de_finalisation',
  TRAJET_ORGANISE = 'trajet_organise',
  ANNULE = 'annule',
}

@Entity('avis_deplacement')
@Index(['statut', 'dateDeplacement', 'role'])
export class AvisDeplacement {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { nullable: false })
  @JoinColumn({ name: 'userId' })
  proprietaire: User;

  @Column({ type: 'enum', enum: RoleAd })
  role: RoleAd;

  @Column({ length: 150 })
  depart: string;

  @Column({ type: 'double precision', nullable: true })
  departLat: number | null;

  @Column({ type: 'double precision', nullable: true })
  departLng: number | null;

  @Column({ length: 150 })
  destination: string;

  @Column({ type: 'double precision', nullable: true })
  arriveeLat: number | null;

  @Column({ type: 'double precision', nullable: true })
  arriveeLng: number | null;

  @Column({ type: 'date' })
  dateDeplacement: string;

  @Column({ length: 5 })
  heureDepart: string;

  @Column({ length: 40, nullable: true })
  moyenTransport: string;

  @Column({ type: 'int', nullable: true })
  placesDisponibles: number;

  @Column({ type: 'enum', enum: StatutAd, default: StatutAd.ACTIF })
  statut: StatutAd;

  @CreateDateColumn()
  creeLe: Date;
}
