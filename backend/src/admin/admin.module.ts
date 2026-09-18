import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { User } from '../users/user.entity';
import { AvisDeplacement } from '../ads/avis-deplacement.entity';
import { Demande } from '../demandes/demande.entity';
import { Signalement } from '../signalements/signalement.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, AvisDeplacement, Demande, Signalement])],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
