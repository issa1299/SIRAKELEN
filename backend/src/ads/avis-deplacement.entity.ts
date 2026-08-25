import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

export enum RoleAd {
  CONDUCTEUR = 'conducteur',
  PASSAGER = 'passager',
}

export enum StatutAd {
  ACTIF = 'actif',
  EN_COURS_DE_FINALISATION = 'en_cours_de_finalisation',
  TRAJET_ORGANISE = 'trajet_organise',
  ANNULE = 'annule',
}

@Entity('avis_deplacement')
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

  @Column({ length: 150 })
  destination: string;

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
