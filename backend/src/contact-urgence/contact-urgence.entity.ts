import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../users/user.entity';

@Entity('contact_urgence')
export class ContactUrgence {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @OneToOne(() => User, (u) => u.contactUrgence)
  @JoinColumn()
  user: User;

  @Column({ length: 120 })
  nomContact: string;

  @Column({ length: 20 })
  telephoneContact: string;

  @Column({ length: 60, nullable: true })
  lien: string;

  @CreateDateColumn()
  creeLe: Date;
}
