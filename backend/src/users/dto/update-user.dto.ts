import { IsOptional, IsString, Matches, MaxLength } from 'class-validator';

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  prenom?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  nom?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  quartier?: string;

  @IsOptional()
  @IsString()
  @Matches(/^[0-9]{8}$/, { message: 'Le numéro doit contenir 8 chiffres' })
  telephone?: string;

  @IsOptional()
  @IsString()
  photoUrl?: string;
}
