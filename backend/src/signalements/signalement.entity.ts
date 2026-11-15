import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { AvisDeplacement } from '../ads/avis-deplacement.entity';

export enum StatutSignalement {
  EN_ATTENTE = 'en_attente',
  TRAITE = 'traite',
}

@Entity('signalements')
export class Signalement {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User)
  utilisateurSignale: User;

  @ManyToOne(() => User)
  auteur: User;

  /** AD signalé (optionnel — null si le signalement vise un utilisateur). */
  @ManyToOne(() => AvisDeplacement, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'adId' })
  ad: AvisDeplacement | null;

  @Column({ length: 255 })
  motif: string;

  @Column({
    type: 'enum',
    enum: StatutSignalement,
    default: StatutSignalement.EN_ATTENTE,
  })
  statut: StatutSignalement;

  @CreateDateColumn()
  creeLe: Date;
}
