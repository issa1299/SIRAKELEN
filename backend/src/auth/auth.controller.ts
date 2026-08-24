import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
} from '@nestjs/common';
import { IsString, Matches } from 'class-validator';
import { AuthService } from './auth.service';

class TelephoneDto {
  @IsString()
  @Matches(/^[0-9]{8}$/, { message: 'Le numéro doit contenir 8 chiffres' })
  telephone: string;
}

class VerifierCodeDto extends TelephoneDto {
  @IsString()
  @Matches(/^[0-9]{4}$/, { message: 'Le code doit contenir 4 chiffres' })
  code: string;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('envoyer-code')
  envoyerCode(@Body() dto: TelephoneDto) {
    return this.authService.envoyerCode(dto.telephone);
  }

  @Post('verifier')
  @HttpCode(HttpStatus.OK)
  verifier(@Body() dto: VerifierCodeDto) {
    return this.authService.verifierCode(dto.telephone, dto.code);
  }
}
