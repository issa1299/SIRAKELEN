import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { IsEnum, IsOptional, IsString, Length } from 'class-validator';
import { EvenementsService } from './evenements.service';
import { TypeEvenement } from './evenement.entity';
import { AdminGuard } from '../admin/admin.guard';
import { Permissions } from '../admin/permissions.decorator';
import { AdminPermission } from '../admin/admin-role.enum';

class EnregistrerEvenementDto {
  @IsEnum(TypeEvenement)
  type: TypeEvenement;

  @IsOptional()
  @IsString()
  @Length(0, 120)
  page?: string;

  @IsOptional()
  @IsString()
  @Length(0, 20)
  plateforme?: string;
}

@Controller()
export class EvenementsController {
  constructor(private readonly service: EvenementsService) {}

  /** Public : enregistre un événement réel (visite, téléchargement). */
  @Post('evenements')
  @HttpCode(201)
  enregistrer(@Body() dto: EnregistrerEvenementDto) {
    return this.service.enregistrer(dto);
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.STATS_LIRE)
  @Get('admin/evenements/serie')
  serie(@Query('type') type: TypeEvenement, @Query('jours') jours?: string) {
    if (!Object.values(TypeEvenement).includes(type)) {
      return [];
    }
    return this.service.serie(type, jours ? parseInt(jours, 10) : 30);
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.STATS_LIRE)
  @Get('admin/evenements/totaux')
  totaux() {
    return this.service.totaux();
  }
}
