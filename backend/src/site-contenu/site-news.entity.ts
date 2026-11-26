import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('site_news')
export class SiteNews {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 200 })
  titre: string;

  @Column({ type: 'text' })
  contenu: string;

  @Column({ length: 500, nullable: true })
  imageUrl: string | null;

  @Column({ type: 'timestamp', nullable: true })
  datePublication: Date | null;

  @Column({ type: 'boolean', default: true })
  actif: boolean;

  @CreateDateColumn()
  creeLe: Date;

  @UpdateDateColumn()
  modifieLe: Date;
}
