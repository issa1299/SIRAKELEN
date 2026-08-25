import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdsService } from './ads.service';
import { AdsController } from './ads.controller';
import { AvisDeplacement } from './avis-deplacement.entity';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [TypeOrmModule.forFeature([AvisDeplacement]), UsersModule],
  controllers: [AdsController],
  providers: [AdsService],
})
export class AdsModule {}
