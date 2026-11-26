import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../users/user.entity';
import { AvisDeplacement } from '../ads/avis-deplacement.entity';
import { Demande } from '../demandes/demande.entity';
import { Signalement } from '../signalements/signalement.entity';
import { Evenement } from '../evenements/evenement.entity';
import { Notification } from '../notifications/notification.entity';
import { AdminLog } from './admin-log.entity';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AdminAuthService } from './admin-auth.service';
import { AdminGuard } from './admin.guard';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      AvisDeplacement,
      Demande,
      Signalement,
      Evenement,
      Notification,
      AdminLog,
    ]),
  ],
  controllers: [AdminController],
  providers: [
    AdminService,
    AdminAuthService,
    AdminGuard,
    // Le guard est appliqué au contrôleur via @UseGuards(AdminGuard),
    // pas globalement (les routes publiques ne doivent pas être bloquées).
  ],
  exports: [AdminService, AdminAuthService, AdminGuard],
})
export class AdminModule {}
