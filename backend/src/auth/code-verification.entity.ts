import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity('codes_verification')
@Index(['telephone'])
export class CodeVerification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 20 })
  telephone: string;

  @Column({ length: 64 })
  codeHash: string;

  @Column({ type: 'int', default: 0 })
  tentatives: number;

  @Column({ type: 'timestamp' })
  expireLe: Date;

  @CreateDateColumn()
  creeLe: Date;
}
