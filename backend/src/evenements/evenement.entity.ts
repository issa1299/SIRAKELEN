import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

/** Événements mesurés réellement (visites, téléchargements). */
export enum TypeEvenement {
  VISITE_SITE = 'visite_site',
  VISITE_PAGE = 'visite_page',
  TELECHARGEMENT_APK = 'telechargement_apk',
  TELECHARGEMENT_WEB = 'telechargement_web',
}

@Entity('evenements')
@Index(['type', 'creeLe'])
export class Evenement {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'enum', enum: TypeEvenement })
  type: TypeEvenement;

  @Column({ length: 120, nullable: true })
  page: string | null;

  @Column({ length: 20, nullable: true })
  plateforme: string | null;

  @CreateDateColumn()
  creeLe: Date;
}
