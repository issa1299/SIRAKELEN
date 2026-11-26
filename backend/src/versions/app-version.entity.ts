import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

export enum Plateforme {
  ANDROID = 'android',
  WEB = 'web',
}

/**
 * Version publiée de l'application (Android ou Web).
 * Une seule version active par plateforme à la fois.
 */
@Entity('app_versions')
@Index(['plateforme', 'actif'])
export class AppVersion {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /** Numéro de version lisible, ex. "1.0.0" (sync avec pubspec.yaml). */
  @Column({ length: 20 })
  version: string;

  /** Code de version entier, ex. 1 (sync avec pubspec.yaml +1). */
  @Column({ type: 'int' })
  buildNumber: number;

  @Column({ type: 'enum', enum: Plateforme })
  plateforme: Plateforme;

  /** URL de téléchargement de l'APK Release (Android uniquement). */
  @Column({ length: 500, nullable: true })
  apkUrl: string | null;

  /** Taille du fichier en octets (optionnel). */
  @Column({ type: 'bigint', nullable: true })
  tailleOctets: number | null;

  /** Notes de mise à jour (une nouveauté par ligne). */
  @Column({ type: 'text' })
  notes: string;

  @Column({ type: 'timestamp' })
  datePublication: Date;

  /** Mise à jour obligatoire : bloque l'accès jusqu'à l'installation. */
  @Column({ type: 'boolean', default: false })
  obligatoire: boolean;

  /** Une seule version active par plateforme. */
  @Column({ type: 'boolean', default: false })
  actif: boolean;

  @CreateDateColumn()
  creeLe: Date;

  @UpdateDateColumn()
  modifieLe: Date;
}
