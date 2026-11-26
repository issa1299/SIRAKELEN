import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Unique,
} from 'typeorm';

/** Contenu éditable du site officiel (clé → valeur), sans toucher au frontend. */
@Entity('site_contenu')
@Unique(['cle'])
export class SiteContenu {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100 })
  cle: string;

  @Column({ type: 'text' })
  valeur: string;

  @Column({ length: 40, default: 'texte' })
  groupe: string;

  @Column({ length: 20, default: 'texte' })
  type: string;

  @Column({ length: 100, nullable: true })
  modifiePar: string | null;

  @CreateDateColumn()
  creeLe: Date;

  @UpdateDateColumn()
  modifieLe: Date;
}
