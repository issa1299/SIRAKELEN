import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

export enum CibleNotification {
  TOUS = 'tous',
  GROUPE = 'groupe',
  INDIVIDUEL = 'individuel',
}

export enum GroupeNotification {
  ACTIFS = 'actifs',
  SUSPENDUS = 'suspendus',
  ADMINS = 'admins',
  VERIFIES = 'verifies',
  NON_VERIFIES = 'non_verifies',
}

export enum StatutNotification {
  BROUILLON = 'brouillon',
  PROGRAMMEE = 'programmee',
  ENVOYEE = 'envoyee',
  ECHOUEE = 'echee',
}

@Entity('notifications')
@Index(['statut', 'creeLe'])
export class Notification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 120 })
  titre: string;

  @Column({ type: 'text' })
  corps: string;

  @Column({ type: 'enum', enum: CibleNotification })
  cible: CibleNotification;

  /** Valeur cible : identifiant utilisateur ou clé de groupe. */
  @Column({ length: 100, nullable: true })
  cibleValeur: string | null;

  @Column({ type: 'enum', enum: StatutNotification, default: StatutNotification.BROUILLON })
  statut: StatutNotification;

  @Column({ type: 'timestamp', nullable: true })
  dateProgramme: Date | null;

  @Column({ type: 'timestamp', nullable: true })
  dateEnvoi: Date | null;

  @Column({ type: 'int', default: 0 })
  destinataires: number;

  @Column({ type: 'int', default: 0 })
  envoyes: number;

  @Column({ type: 'int', default: 0 })
  echecs: number;

  /** Compte-rendu réel de l'envoi (ex. « FCM non configuré »). */
  @Column({ type: 'text', nullable: true })
  resultat: string | null;

  @Column({ length: 100, nullable: true })
  creePar: string | null;

  @Column({ length: 80, nullable: true })
  creeParPrenom: string | null;

  @CreateDateColumn()
  creeLe: Date;
}
