import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
} from 'typeorm';
import { User } from '../users/user.entity';
import { Demande } from '../demandes/demande.entity';

/** Message de discussion lie a une demande (visible des 2 partenaires uniquement). */
@Entity('messages')
export class Message {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Demande, { nullable: false, onDelete: 'CASCADE' })
  demande: Demande;

  @ManyToOne(() => User, { nullable: false })
  auteur: User;

  @Column({ length: 500 })
  contenu: string;

  @CreateDateColumn()
  creeLe: Date;
}
