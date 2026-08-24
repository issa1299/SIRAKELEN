import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  async create(dto: CreateUserDto): Promise<User> {
    const telephone = this.normalizeTelephone(dto.telephone);
    const existant = await this.usersRepository.findOne({
      where: { telephone },
    });
    if (existant) {
      throw new ConflictException('Ce numéro est déjà associé à un compte');
    }
    const user = this.usersRepository.create({
      prenom: dto.prenom.trim(),
      nom: dto.nom.trim(),
      telephone,
      quartier: dto.quartier.trim(),
      verifie: false,
    });
    return this.usersRepository.save(user);
  }

  async findOne(id: string): Promise<User> {
    const user = await this.usersRepository.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }
    return user;
  }

  async findByTelephone(telephone: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { telephone: this.normalizeTelephone(telephone) },
    });
  }

  async update(id: string, dto: UpdateUserDto): Promise<User> {
    const user = await this.findOne(id);
    Object.assign(user, dto);
    return this.usersRepository.save(user);
  }

  private normalizeTelephone(telephone: string): string {
    return telephone.replace(/\s+/g, '');
  }
}
