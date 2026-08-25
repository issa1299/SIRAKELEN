import { Body, Controller, Get, Param, ParseUUIDPipe, Post } from '@nestjs/common';
import { AdsService } from './ads.service';
import { CreateAdDto } from './dto/create-ad.dto';
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
