import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SecuriteController } from './securite.controller';
import { ContactUrgenceService } from './contact-urgence.service';
import { SignalementsService } from './signalements.service';
import { ContactUrgence } from '../contact-urgence/contact-urgence.entity';
import { Signalement } from '../signalements/signalement.entity';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([ContactUrgence, Signalement]),
    UsersModule,
  ],
  controllers: [SecuriteController],
  providers: [ContactUrgenceService, SignalementsService],
})
export class SecuriteModule {}
