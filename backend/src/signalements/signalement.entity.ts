import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
} from 'typeorm';
import { User } from '../users/user.entity';

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
