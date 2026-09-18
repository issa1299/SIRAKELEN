import {
  IsDateString,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { RoleAd } from '../avis-deplacement.entity';

export class CreateAdDto {
  @IsUUID()
  userId: string;

  @IsEnum(RoleAd, { message: 'Le rôle doit être conducteur ou passager' })
  role: RoleAd;

  @IsString()
  @IsNotEmpty({ message: 'Le point de départ est obligatoire' })
  @MaxLength(150)
  depart: string;

  @IsOptional()
  @IsNumber()
  departLat?: number;

  @IsOptional()
  @IsNumber()
  departLng?: number;

  @IsString()
  @IsNotEmpty({ message: 'La destination est obligatoire' })
  @MaxLength(150)
  destination: string;

  @IsOptional()
  @IsNumber()
  arriveeLat?: number;

  @IsOptional()
  @IsNumber()
  arriveeLng?: number;

  @IsDateString({}, { message: 'Date de déplacement invalide' })
  dateDeplacement: string;

  @IsString()
  @Matches(/^([01][0-9]|2[0-3]):[0-5][0-9]$/, {
    message: 'Heure invalide (format HH:mm)',
  })
  heureDepart: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  moyenTransport?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(10)
  placesDisponibles?: number;
}
