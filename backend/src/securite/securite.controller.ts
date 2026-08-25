import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
} from '@nestjs/common';
import { IsNotEmpty, IsOptional, IsString, IsUUID, MaxLength, Matches } from 'class-validator';
import { ContactUrgenceService } from './contact-urgence.service';
import { SignalementsService } from './signalements.service';
import { UsersService } from '../users/users.service';

class ContactUrgenceDto {
  @IsUUID()
  userId: string;

  @IsString()
  @IsNotEmpty({ message: 'Le nom du contact est obligatoire' })
  @MaxLength(120)
  nomContact: string;

  @IsString()
  @Matches(/^[0-9]{8}$/, { message: 'Le numéro du contact doit contenir 8 chiffres' })
  telephoneContact: string;

  @IsOptional()
  @IsString()
  @MaxLength(60)
  lien?: string;
}

class SignalerDto {
  @IsUUID()
  signaleUserId: string;

  @IsUUID()
  auteurId: string;

  @IsString()
  @IsNotEmpty({ message: 'Le motif est obligatoire' })
  @MaxLength(255)
  motif: string;
}

@Controller('securite')
export class SecuriteController {
  constructor(
    private readonly contactUrgenceService: ContactUrgenceService,
    private readonly signalementsService: SignalementsService,
    private readonly usersService: UsersService,
  ) {}

  @Put('contact-urgence')
  definirContact(@Body() dto: ContactUrgenceDto) {
    return this.contactUrgenceService.definir(dto);
  }

  @Get('contact-urgence/:userId')
  voirContact(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.contactUrgenceService.de(userId);
  }

  /** Contact d'urgence du partenaire confirmé (visible après acceptation). */
  @Get('contact-urgence-partenaire/:adId/:demandeurId')
  contactPartenaire(
    @Param('adId', ParseUUIDPipe) adId: string,
    @Param('demandeurId', ParseUUIDPipe) demandeurId: string,
  ) {
    return this.contactUrgenceService.contactPartenaireConfirmé(
      adId,
      demandeurId,
    );
  }

  @Post('signalements')
  signaler(@Body() dto: SignalerDto) {
    return this.signalementsService.signaler(dto);
  }

  @Get('stats/:userId')
  async stats(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.usersService.stats(userId);
  }
}
