import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
} from '@nestjs/common';
import { IsString, Matches, IsOptional } from 'class-validator';

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

class CodeRecuperationDto extends TelephoneDto {
  @IsString()
  @Matches(/^[0-9]{4}$/, { message: 'Le code de récupération doit contenir 4 chiffres' })
  codeRecuperation: string;
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

class GoogleLoginDto {
  @IsString()
  googleId: string;
  @IsString()
  email: string;
  @IsString()
  prenom: string;
  @IsString()
  nom: string;
  @IsOptional()
  @IsString()
  photoUrl?: string;
}

class AppleLoginDto {
  @IsString()
  appleId: string;
  @IsOptional()
  @IsString()
  email?: string;
  @IsOptional()
  @IsString()
  prenom?: string;
  @IsOptional()
  @IsString()
  nom?: string;
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

  @Post('definir-code-recuperation')
  @HttpCode(HttpStatus.OK)
  async definirCodeRecuperation(@Body() dto: CodeRecuperationDto) {
    return this.authService.definirCodeRecuperation(dto.telephone, dto.codeRecuperation);
  }

  @Post('verifier-code-recuperation')
  @HttpCode(HttpStatus.OK)
  async verifierCodeRecuperation(@Body() dto: CodeRecuperationDto) {
    return this.authService.verifierCodeRecuperation(dto.telephone, dto.codeRecuperation);
  }

  @Post('google')
  @HttpCode(HttpStatus.OK)
  async googleLogin(@Body() dto: GoogleLoginDto) {
    return this.authService.googleLogin(dto);
  }

  @Post('apple')
  @HttpCode(HttpStatus.OK)
  async appleLogin(@Body() dto: AppleLoginDto) {
    return this.authService.appleLogin(dto);
  }
}