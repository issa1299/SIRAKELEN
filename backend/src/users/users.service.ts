import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { AvisDeplacement } from '../ads/avis-deplacement.entity';
import { Signalement } from '../signalements/signalement.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(AvisDeplacement)
    private readonly adsRepository: Repository<AvisDeplacement>,
    @InjectRepository(Signalement)
    private readonly signalementsRepository: Repository<Signalement>,
  ) {}

  async create(dto: CreateUserDto): Promise<User> {
    const telephone = this.normalizeTelephone(dto.telephone);
    const existant = await this.usersRepository.findOne({
      where: [{ telephone }, { email: dto.email }],
    });
    if (existant) {
      if (existant.telephone === telephone) {
        throw new ConflictException('Ce numéro est déjà associé à un compte');
      }
      throw new ConflictException('Cet email est déjà associé à un compte');
    }
    const user = this.usersRepository.create({
      prenom: dto.prenom.trim(),
      nom: dto.nom.trim(),
      telephone,
      email: dto.email.toLowerCase().trim(),
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

  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { email: email.toLowerCase().trim() },
    });
  }

  async findByGoogleId(googleId: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { googleId } });
  }

  async findByAppleId(appleId: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { appleId } });
  }

  async updateRaw(user: User): Promise<User> {
    return this.usersRepository.save(user);
  }

  async createOAuth(data: {
    prenom: string;
    nom: string;
    email?: string;
    googleId?: string;
    appleId?: string;
    photoUrl?: string;
  }): Promise<User> {
    const user = this.usersRepository.create({
      prenom: data.prenom.trim(),
      nom: data.nom.trim(),
      telephone: '',
      email: data.email?.toLowerCase().trim() ?? null,
      quartier: '',
      verifie: true,
      googleId: data.googleId ?? null,
      appleId: data.appleId ?? null,
      photoUrl: data.photoUrl ?? null,
    });
    return this.usersRepository.save(user);
  }

  async marquerVerifie(id: string): Promise<User> {
    const user = await this.findOne(id);
    user.verifie = true;
    return this.usersRepository.save(user);
  }

  async definirCodeRecuperation(id: string, code: string): Promise<User> {
    const user = await this.findOne(id);
    user.codeRecuperation = code;
    return this.usersRepository.save(user);
  }

  async verifierCodeRecuperation(telephone: string, code: string): Promise<User | null> {
    const user = await this.findByTelephone(telephone);
    if (!user || user.codeRecuperation !== code) return null;
    return user;
  }

  async update(id: string, dto: UpdateUserDto): Promise<User> {
    const user = await this.findOne(id);
    Object.assign(user, dto);
    return this.usersRepository.save(user);
  }

  async stats(userId: string): Promise<{
    adPublies: number;
    trajetsOrganises: number;
    signalements: number;
  }> {
    const user = await this.findOne(userId);
    const ads = await this.usersRepository
      .createQueryBuilder('u')
      .leftJoin('u.ads', 'a')
      .where('u.id = :id', { id: userId })
      .getMany();
    void ads;
    const adPublies = await this.adsRepository.count({
      where: { proprietaire: { id: userId } },
    });
    const trajetsOrganises = await this.adsRepository.count({
      where: { proprietaire: { id: userId }, statut: 'trajet_organise' as never },
    });
    const signalements = await this.signalementsRepository.count({
      where: { utilisateurSignale: { id: userId } },
    });
    return { adPublies, trajetsOrganises, signalements };
  }

  private normalizeTelephone(telephone: string): string {
    return telephone.replace(/\s+/g, '');
  }
}
