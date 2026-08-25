import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { User } from './user.entity';
import { AvisDeplacement } from '../ads/avis-deplacement.entity';
import { Signalement } from '../signalements/signalement.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, AvisDeplacement, Signalement]),
  ],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
