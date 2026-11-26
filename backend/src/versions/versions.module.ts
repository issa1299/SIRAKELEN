import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppVersion } from './app-version.entity';
import { VersionsService } from './versions.service';
import { VersionsController } from './versions.controller';

@Module({
  imports: [TypeOrmModule.forFeature([AppVersion])],
  controllers: [VersionsController],
  providers: [VersionsService],
  exports: [VersionsService],
})
export class VersionsModule {}
