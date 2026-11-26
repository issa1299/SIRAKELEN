import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('site_faq')
export class SiteFaq {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 300 })
  question: string;

  @Column({ type: 'text' })
  reponse: string;

  @Column({ type: 'int', default: 0 })
  ordre: number;

  @Column({ type: 'boolean', default: true })
  actif: boolean;

  @CreateDateColumn()
  creeLe: Date;

  @UpdateDateColumn()
  modifieLe: Date;
}
