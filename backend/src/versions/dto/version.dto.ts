import {
  IsString,
  IsInt,
  IsEnum,
  IsOptional,
  IsUrl,
  IsNumber,
  Min,
  MaxLength,
} from 'class-validator';
import { Plateforme } from '../app-version.entity';

export class CreerVersionDto {
  @IsString()
  @MaxLength(20)
  version: string;

  @IsInt()
  @Min(1)
  buildNumber: number;

  @IsEnum(Plateforme)
  plateforme: Plateforme;

  @IsOptional()
  @IsUrl({}, { message: 'URL de l’APK invalide' })
  apkUrl?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  tailleOctets?: number;

  @IsString()
  @MaxLength(2000)
  notes: string;

  @IsOptional()
  datePublication?: Date;

  @IsOptional()
  obligatoire?: boolean;

  // actif n'est pas accepté : une version créée n'est jamais publiée automatiquement.
}

export class ModifierVersionDto {
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;

  @IsOptional()
  obligatoire?: boolean;

  @IsOptional()
  @IsUrl({}, { message: 'URL de l’APK invalide' })
  apkUrl?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  tailleOctets?: number;
}
