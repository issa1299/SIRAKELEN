import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
  Unique,
} from 'typeorm';

/** Token FCM enregistré par un utilisateur (jamais exposé publiquement). */
@Entity('notification_tokens')
@Index(['userId'])
@Unique(['token'])
export class NotificationToken {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100 })
  userId: string;

  @Column({ type: 'text' })
  token: string;

  @Column({ length: 20, default: 'android' })
  plateforme: string;

  @Column({ type: 'boolean', default: true })
  actif: boolean;

  @CreateDateColumn()
  creeLe: Date;
}
