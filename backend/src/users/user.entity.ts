import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToOne,
  OneToMany,
} from 'typeorm';
import { ContactUrgence } from '../contact-urgence/contact-urgence.entity';
import { AvisDeplacement } from '../ads/avis-deplacement.entity';
import { Demande } from '../demandes/demande.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 80 })
  prenom: string;

  @Column({ length: 80 })
  nom: string;

  @Column({ length: 20, unique: true })
  telephone: string;

  @Column({ length: 120 })
  quartier: string;

  @Column({ nullable: true })
  photoUrl: string;

  @Column({ default: false })
  verifie: boolean;

  @CreateDateColumn()
  creeLe: Date;

  @OneToOne(() => ContactUrgence, (c) => c.user, { nullable: true })
  contactUrgence: ContactUrgence;

  @OneToMany(() => AvisDeplacement, (ad) => ad.proprietaire)
  ads: AvisDeplacement[];

  @OneToMany(() => Demande, (d) => d.demandeur)
  demandesEnvoyees: Demande[];
}
