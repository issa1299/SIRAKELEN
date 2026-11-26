import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { User } from './users/user.entity';
import { AvisDeplacement } from './ads/avis-deplacement.entity';
import { Demande } from './demandes/demande.entity';
import { Signalement } from './signalements/signalement.entity';
import { ContactUrgence } from './contact-urgence/contact-urgence.entity';
import { CodeVerification } from './auth/code-verification.entity';
import { Message } from './messages/message.entity';
import { AppVersion } from './versions/app-version.entity';
import { AdminLog } from './admin/admin-log.entity';
import { Evenement } from './evenements/evenement.entity';
import { Notification } from './notifications/notification.entity';
import { NotificationToken } from './notifications/notification-token.entity';
import { SiteContenu } from './site-contenu/site-contenu.entity';
import { SiteNews } from './site-contenu/site-news.entity';
import { SiteFaq } from './site-contenu/site-faq.entity';
import { PlateformeModule } from './plateforme.module';
import { VersionsModule } from './versions/versions.module';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { AdsModule } from './ads/ads.module';
import { DemandesModule } from './demandes/demandes.module';
import { SecuriteModule } from './securite/securite.module';
import { UploadModule } from './upload/upload.module';
import { AdminModule } from './admin/admin.module';
import { MessagesModule } from './messages/messages.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        // Production (Supabase/Render) : une seule URL + SSL obligatoire.
        const databaseUrl = config.get<string>('DATABASE_URL');
        if (databaseUrl) {
          return {
            type: 'postgres' as const,
            url: databaseUrl,
            ssl: { rejectUnauthorized: false },
            entities: [User, AvisDeplacement, Demande, Signalement, ContactUrgence, CodeVerification, Message, AppVersion, AdminLog, Evenement, Notification, NotificationToken, SiteContenu, SiteNews, SiteFaq],
            synchronize: true,
          };
        }
        // Developpement local : variables separees, sans SSL.
        return {
          type: 'postgres' as const,
          host: config.get<string>('DB_HOST'),
          port: parseInt(config.get<string>('DB_PORT', '5432'), 10),
          username: config.get<string>('DB_USER'),
          password: config.get<string>('DB_PASSWORD'),
          database: config.get<string>('DB_NAME'),
          entities: [User, AvisDeplacement, Demande, Signalement, ContactUrgence, CodeVerification, Message, AppVersion, AdminLog, Evenement, Notification, NotificationToken, SiteContenu, SiteNews, SiteFaq],
          synchronize: true,
        };
      },
    }),
    VersionsModule,
    UsersModule,
    AuthModule,
    AdsModule,
    DemandesModule,
    SecuriteModule,
    UploadModule,
    AdminModule,
    MessagesModule,
    PlateformeModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
