import { IsOptional, IsString, MaxLength } from 'class-validator';

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
  photoUrl?: string;
}
