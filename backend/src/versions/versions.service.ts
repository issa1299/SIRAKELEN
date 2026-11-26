import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AppVersion, Plateforme } from './app-version.entity';

export interface CreerVersionDto {
  version: string;
  buildNumber: number;
  plateforme: Plateforme;
  apkUrl?: string;
  tailleOctets?: number;
  notes: string;
  datePublication?: Date;
  obligatoire?: boolean;
  actif?: boolean;
}

@Injectable()
export class VersionsService {
  constructor(
    @InjectRepository(AppVersion)
    private readonly repo: Repository<AppVersion>,
  ) {}

  /** Dernière version active d'une plateforme (endpoint public). */
  async derniere(plateforme: Plateforme): Promise<AppVersion | null> {
    return this.repo.findOne({
      where: { plateforme, actif: true },
      order: { datePublication: 'DESC' },
    });
  }

  /** Toutes les versions (admin). */
  async findAll(): Promise<AppVersion[]> {
    return this.repo.find({ order: { datePublication: 'DESC' } });
  }

  async findOne(id: string): Promise<AppVersion> {
    const v = await this.repo.findOne({ where: { id } });
    if (!v) throw new NotFoundException('Version introuvable');
    return v;
  }

  /** Créer une version (brouillon par défaut, non publiée). */
  async creer(dto: CreerVersionDto): Promise<AppVersion> {
    if (!dto.version?.trim()) {
      throw new BadRequestException('Le numéro de version est obligatoire');
    }
    if (!Number.isInteger(dto.buildNumber) || dto.buildNumber < 1) {
      throw new BadRequestException('Le code de version doit être un entier > 0');
    }
    if (!dto.notes?.trim()) {
      throw new BadRequestException('Les notes de mise à jour sont obligatoires');
    }
    if (dto.plateforme === Plateforme.ANDROID && !dto.apkUrl?.trim()) {
      throw new BadRequestException('L’URL de l’APK est obligatoire pour Android');
    }

    const version = this.repo.create({
      version: dto.version.trim(),
      buildNumber: dto.buildNumber,
      plateforme: dto.plateforme,
      apkUrl: dto.apkUrl?.trim() || null,
      tailleOctets: dto.tailleOctets ?? null,
      notes: dto.notes.trim(),
      datePublication: dto.datePublication ?? new Date(),
      obligatoire: dto.obligatoire ?? false,
      // Sécurité : une version créée n'est jamais publiée automatiquement.
      actif: false,
    });
    return this.repo.save(version);
  }

  /** Publier une version : désactive les autres versions de la plateforme. */
  async publier(id: string): Promise<AppVersion> {
    const version = await this.findOne(id);

    await this.repo.update(
      { plateforme: version.plateforme, actif: true },
      { actif: false },
    );

    version.actif = true;
    version.datePublication = new Date();
    return this.repo.save(version);
  }

  /** Désactiver une version. */
  async desactiver(id: string): Promise<AppVersion> {
    const version = await this.findOne(id);
    version.actif = false;
    return this.repo.save(version);
  }

  /** Modifier les notes / le caractère obligatoire d'une version. */
  async modifier(
    id: string,
    dto: { notes?: string; obligatoire?: boolean; apkUrl?: string; tailleOctets?: number },
  ): Promise<AppVersion> {
    const version = await this.findOne(id);
    if (dto.notes !== undefined) {
      if (!dto.notes.trim()) {
        throw new BadRequestException('Les notes ne peuvent pas être vides');
      }
      version.notes = dto.notes.trim();
    }
    if (dto.obligatoire !== undefined) version.obligatoire = dto.obligatoire;
    if (dto.apkUrl !== undefined) version.apkUrl = dto.apkUrl.trim() || null;
    if (dto.tailleOctets !== undefined) version.tailleOctets = dto.tailleOctets;
    return this.repo.save(version);
  }
}
