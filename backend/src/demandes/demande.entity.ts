import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
} from 'typeorm';
import { User } from '../users/user.entity';
import { AvisDeplacement } from '../ads/avis-deplacement.entity';

export enum StatutDemande {
  EN_ATTENTE = 'en_attente',
  ACCEPTEE = 'acceptee',
  REFUSEE = 'refusee',
  ANNULEE = 'annulee',
}

@Entity('demandes')
export class Demande {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => AvisDeplacement)
  ad: AvisDeplacement;

  @ManyToOne(() => User, (u) => u.demandesEnvoyees)
  demandeur: User;

  @Column({ type: 'enum', enum: StatutDemande, default: StatutDemande.EN_ATTENTE })
  statut: StatutDemande;

  @CreateDateColumn()
  creeLe: Date;
}
