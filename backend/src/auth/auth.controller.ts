import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
} from '@nestjs/common';
import { IsString, Matches } from 'class-validator';

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

class EmailDto {
  @IsString()
  email: string;
}

class VerifierEmailDto {
  @IsString()
  email: string;
  @IsString()
  @Matches(/^[0-9]{4,6}$/, { message: 'Le code doit contenir 4 à 6 chiffres' })
  code: string;
}

import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('envoyer-code')
  @HttpCode(HttpStatus.OK)
  async envoyerCode(@Body() dto: TelephoneDto) {
    return this.authService.envoyerCode(dto.telephone);
  }

  @Post('envoyer-code-email')
  @HttpCode(HttpStatus.OK)
  async envoyerCodeEmail(@Body() dto: EmailDto) {
    return this.authService.envoyerCodeEmail(dto.email);
  }

  @Post('verifier')
  @HttpCode(HttpStatus.OK)
  verifier(@Body() dto: VerifierCodeDto) {
    return this.authService.verifierCode(dto.telephone, dto.code);
  }

  @Post('verifier-email')
  @HttpCode(HttpStatus.OK)
  async verifierEmail(@Body() dto: VerifierEmailDto) {
    return this.authService.verifierCodeEmail(dto.email, dto.code);
  }
}