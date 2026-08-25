import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DemandesService } from './demandes.service';
import { DemandesController } from './demandes.controller';
import { Demande } from './demande.entity';
import { AvisDeplacement } from '../ads/avis-deplacement.entity';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Demande, AvisDeplacement]),
    UsersModule,
  ],
  controllers: [DemandesController],
  providers: [DemandesService],
})
export class DemandesModule {}
