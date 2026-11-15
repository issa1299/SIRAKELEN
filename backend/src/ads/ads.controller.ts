import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { AdsService } from './ads.service';
import { CreateAdDto } from './dto/create-ad.dto';
import { ListerAdsDto } from './dto/lister-ads.dto';
import { AvisDeplacement } from './avis-deplacement.entity';

@Controller('ads')
export class AdsController {
  constructor(private readonly adsService: AdsService) {}

  @Post()
  creer(@Body() dto: CreateAdDto): Promise<AvisDeplacement> {
    return this.adsService.creer(dto);
  }

  @Get('mine/:userId')
  mesAds(@Param('userId', ParseUUIDPipe) userId: string): Promise<AvisDeplacement[]> {
    return this.adsService.mesAds(userId);
  }

  @Get('compatibilites/:userId')
  compatibilites(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.adsService.compatibilites(userId);
  }

  /** Parcourir tous les AD actifs (acces conditionne a un AD actif non expire). */
  @Get('parcourir/:userId')
  parcourir(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query() query: ListerAdsDto,
  ) {
    return this.adsService.parcourir(userId, query);
  }

  /** Trajets publics d'un utilisateur (vue profil d'un autre). */
  @Get('publiques/:userId')
  publiques(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.adsService.trajetsPublics(userId);
  }

  @Post(':id/annuler/:userId')
  annuler(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('userId', ParseUUIDPipe) userId: string,
  ): Promise<AvisDeplacement> {
    return this.adsService.annuler(id, userId);
  }
}
