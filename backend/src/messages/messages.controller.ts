import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
} from '@nestjs/common';
import { IsString, IsUUID, MaxLength, MinLength } from 'class-validator';
import { MessagesService } from './messages.service';

class EnvoyerMessageDto {
  @IsUUID()
  demandeId: string;

  @IsUUID()
  auteurId: string;

  @IsString()
  @MinLength(1)
  @MaxLength(500)
  contenu: string;
}

@Controller('messages')
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  @Post()
  envoyer(@Body() dto: EnvoyerMessageDto) {
    return this.messagesService.envoyer(
      dto.demandeId,
      dto.auteurId,
      dto.contenu,
    );
  }

  @Get(':demandeId/:userId')
  conversation(
    @Param('demandeId', ParseUUIDPipe) demandeId: string,
    @Param('userId', ParseUUIDPipe) userId: string,
  ) {
    return this.messagesService.conversation(demandeId, userId);
  }
}
