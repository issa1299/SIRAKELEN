import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity('codes_verification')
@Index(['telephone'])
@Index(['email'])
export class CodeVerification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 20, nullable: true })
  telephone: string;

  @Column({ length: 100 })
  email: string;

  @Column({ length: 64 })
  codeHash: string;

  @Column({ type: 'int', default: 0 })
  tentatives: number;

  @Column({ type: 'timestamp' })
  expireLe: Date;

  @CreateDateColumn()
  creeLe: Date;
}