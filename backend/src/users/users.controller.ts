import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  ParseUUIDPipe,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { User } from './user.entity';

/**
 * Champs privés : jamais renvoyés par les endpoints publics.
 * (Le hachage du mot de passe et le code de récupération restent côté serveur.)
 */
function nettoyer(user: User | null): User | null {
  if (!user) return null;
  const { motDePasse, codeRecuperation, ...propre } = user;
  void motDePasse;
  void codeRecuperation;
  return propre as User;
}

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  async register(@Body() dto: CreateUserDto): Promise<User | null> {
    return nettoyer(await this.usersService.create(dto));
  }

  @Post('recherche')
  @HttpCode(HttpStatus.OK)
  async findByTelephone(
    @Body() body: { telephone?: string; email?: string },
  ): Promise<User | null> {
    if (body.email) {
      return nettoyer(await this.usersService.findByEmail(body.email));
    }
    return nettoyer(await this.usersService.findByTelephone(body.telephone ?? ''));
  }

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string): Promise<User | null> {
    return nettoyer(await this.usersService.findOne(id));
  }

  @Patch(':id/verifier')
  async verifier(@Param('id', ParseUUIDPipe) id: string): Promise<User | null> {
    return nettoyer(await this.usersService.marquerVerifie(id));
  }

  @Patch(':id')
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserDto,
  ): Promise<User | null> {
    return nettoyer(await this.usersService.update(id, dto));
  }
}
