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
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { AdsModule } from './ads/ads.module';
import { DemandesModule } from './demandes/demandes.module';
import { SecuriteModule } from './securite/securite.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres' as const,
        host: config.get<string>('DB_HOST'),
        port: parseInt(config.get<string>('DB_PORT', '5432'), 10),
        username: config.get<string>('DB_USER'),
        password: config.get<string>('DB_PASSWORD'),
        database: config.get<string>('DB_NAME'),
        entities: [User, AvisDeplacement, Demande, Signalement, ContactUrgence, CodeVerification],
        synchronize: true,
      }),
    }),
    UsersModule,
    AuthModule,
    AdsModule,
    DemandesModule,
    SecuriteModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
