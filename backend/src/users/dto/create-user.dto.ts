import { IsString, IsNotEmpty, Matches, MaxLength } from 'class-validator';

export class CreateUserDto {
  @IsString()
  @IsNotEmpty({ message: 'Le prénom est obligatoire' })
  @MaxLength(80)
  prenom: string;

  @IsString()
  @IsNotEmpty({ message: 'Le nom est obligatoire' })
  @MaxLength(80)
  nom: string;

  @IsString()
  @Matches(/^[0-9]{8}$/, {
    message: 'Le numéro doit contenir 8 chiffres (ex. 70123456)',
  })
  telephone: string;

  @IsString()
  @IsNotEmpty({ message: 'Le quartier est obligatoire' })
  @MaxLength(120)
  quartier: string;
}
