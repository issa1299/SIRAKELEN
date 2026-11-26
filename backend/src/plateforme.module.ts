import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminModule } from './admin/admin.module';

import { Evenement } from './evenements/evenement.entity';
import { EvenementsService } from './evenements/evenements.service';
import { EvenementsController } from './evenements/evenements.controller';

import { Notification } from './notifications/notification.entity';
import { NotificationToken } from './notifications/notification-token.entity';
import { NotificationsService } from './notifications/notifications.service';
import { NotificationsController } from './notifications/notifications.controller';
import { FcmService } from './notifications/fcm.service';

import { SiteContenu } from './site-contenu/site-contenu.entity';
import { SiteNews } from './site-contenu/site-news.entity';
import { SiteFaq } from './site-contenu/site-faq.entity';
import { SiteContenuService } from './site-contenu/site-contenu.service';
import { SiteContenuController } from './site-contenu/site-contenu.controller';

import { SauvegardesService } from './sauvegardes/sauvegardes.service';
import { SauvegardesController } from './sauvegardes/sauvegardes.controller';

/** Modules transverses de la plateforme pilotés depuis l'admin centralisé. */
@Module({
  imports: [
    TypeOrmModule.forFeature([
      Evenement,
      Notification,
      NotificationToken,
      SiteContenu,
      SiteNews,
      SiteFaq,
    ]),
    AdminModule,
  ],
  controllers: [
    EvenementsController,
    NotificationsController,
    SiteContenuController,
    SauvegardesController,
  ],
  providers: [
    EvenementsService,
    NotificationsService,
    FcmService,
    SiteContenuService,
    SauvegardesService,
  ],
  exports: [EvenementsService, NotificationsService, SiteContenuService],
})
export class PlateformeModule {}
