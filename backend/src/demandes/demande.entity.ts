import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  Unique,
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
@Unique(['ad', 'demandeur'])
export class Demande {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => AvisDeplacement, { nullable: false })
  ad: AvisDeplacement;

  @ManyToOne(() => User, { nullable: false })
  demandeur: User;

  @Column({ type: 'enum', enum: StatutDemande, default: StatutDemande.EN_ATTENTE })
  statut: StatutDemande;

  @CreateDateColumn()
  creeLe: Date;
}
