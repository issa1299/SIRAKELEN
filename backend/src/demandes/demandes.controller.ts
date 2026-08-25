import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
} from '@nestjs/common';
import { IsUUID } from 'class-validator';
import { DemandesService } from './demandes.service';

class EnvoyerDemandeDto {
  @IsUUID()
  adId: string;

  @IsUUID()
  demandeurId: string;
}

@Controller('demandes')
export class DemandesController {
  constructor(private readonly demandesService: DemandesService) {}

  @Post()
  envoyer(@Body() dto: EnvoyerDemandeDto) {
    return this.demandesService.envoyer(dto.adId, dto.demandeurId);
  }

  @Get('recues/:userId')
  recues(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.demandesService.recues(userId);
  }

  @Get('envoyees/:userId')
  envoyees(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.demandesService.envoyees(userId);
  }

  @Post(':id/accepter/:userId')
  accepter(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('userId', ParseUUIDPipe) userId: string,
  ) {
    return this.demandesService.accepter(id, userId);
  }

  @Post(':id/refuser/:userId')
  refuser(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('userId', ParseUUIDPipe) userId: string,
  ) {
    return this.demandesService.refuser(id, userId);
  }

  @Post(':id/annuler/:userId')
  annuler(
    @Param('id', ParseUUIDPipe) id: string,
    @Param('userId', ParseUUIDPipe) userId: string,
  ) {
    return this.demandesService.annuler(id, userId);
  }

  @Post('ads/:adId/organise/:userId')
  marquerOrganise(
    @Param('adId', ParseUUIDPipe) adId: string,
    @Param('userId', ParseUUIDPipe) userId: string,
  ) {
    return this.demandesService.marquerOrganise(adId, userId);
  }
}
