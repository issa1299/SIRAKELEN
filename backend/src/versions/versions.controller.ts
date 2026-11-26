import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { VersionsService } from './versions.service';
import { Plateforme } from './app-version.entity';
import { CreerVersionDto, ModifierVersionDto } from './dto/version.dto';

@Controller('versions')
export class VersionsController {
  constructor(private readonly versionsService: VersionsService) {}

  /** Endpoint public : dernière version active pour une plateforme. */
  @Get('latest')
  latest(@Query('plateforme') plateforme: string) {
    const p = String(plateforme || '').toLowerCase();
    if (p !== Plateforme.ANDROID && p !== Plateforme.WEB) {
      return null;
    }
    return this.versionsService.derniere(p as Plateforme);
  }

  /** Administration : liste de toutes les versions. */
  @Get('all')
  all() {
    return this.versionsService.findAll();
  }

  @Get(':id')
  one(@Param('id', ParseUUIDPipe) id: string) {
    return this.versionsService.findOne(id);
  }

  @Post()
  creer(@Body() dto: CreerVersionDto) {
    return this.versionsService.creer(dto);
  }

  @Post(':id/publier')
  publier(@Param('id', ParseUUIDPipe) id: string) {
    return this.versionsService.publier(id);
  }

  @Post(':id/desactiver')
  desactiver(@Param('id', ParseUUIDPipe) id: string) {
    return this.versionsService.desactiver(id);
  }

  @Patch(':id')
  modifier(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ModifierVersionDto,
  ) {
    return this.versionsService.modifier(id, dto);
  }
}
