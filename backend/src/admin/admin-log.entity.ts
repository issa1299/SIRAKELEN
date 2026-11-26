import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity('admin_logs')
@Index(['creeLe'])
@Index(['adminId'])
export class AdminLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 100 })
  adminId: string;

  @Column({ length: 80, nullable: true })
  adminPrenom: string | null;

  @Column({ length: 120 })
  action: string;

  @Column({ length: 80, nullable: true })
  objetType: string | null;

  @Column({ length: 100, nullable: true })
  objetId: string | null;

  @Column({ type: 'text', nullable: true })
  detail: string | null;

  @Column({ length: 45, nullable: true })
  ip: string | null;

  @CreateDateColumn()
  creeLe: Date;
}
