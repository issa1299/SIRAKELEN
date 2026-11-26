import {
  IsEmail,
  IsEnum,
  IsIn,
  IsOptional,
  IsString,
  Length,
  MinLength,
} from 'class-validator';
import { AdminRole } from '../admin-role.enum';
import { StatutUtilisateur } from '../../users/user.entity';
import { StatutAd } from '../../ads/avis-deplacement.entity';

export class LoginAdminDto {
  @IsEmail({}, { message: 'Email invalide' })
  email: string;

  @IsString()
  @MinLength(1, { message: 'Mot de passe requis' })
  motDePasse: string;
}

export class UpdateProfilDto {
  @IsOptional()
  @IsString()
  @Length(2, 80)
  prenom?: string;

  @IsOptional()
  @IsString()
  @Length(1, 80)
  nom?: string;
}

export class ChangerMotDePasseDto {
  @IsString()
  ancien: string;

  @IsString()
  @MinLength(8, { message: 'Au moins 8 caractères' })
  nouveau: string;
}

export class UpdateUserAdminDto {
  @IsOptional()
  @IsString()
  @Length(2, 80)
  prenom?: string;

  @IsOptional()
  @IsString()
  @Length(1, 80)
  nom?: string;

  @IsOptional()
  @IsString()
  @Length(1, 120)
  quartier?: string;

  @IsOptional()
  @IsString()
  @Length(8, 20)
  telephone?: string;
}

export class SuspendreUserDto {
  @IsEnum(StatutUtilisateur)
  statut: StatutUtilisateur;

  @IsOptional()
  @IsString()
  @Length(0, 200)
  motif?: string;
}

export class ModifierStatutAdDto {
  @IsEnum(StatutAd)
  statut: StatutAd;
}

export class ModifierAdDto {
  @IsOptional()
  @IsString()
  @Length(1, 150)
  depart?: string;

  @IsOptional()
  @IsString()
  @Length(1, 150)
  destination?: string;

  @IsOptional()
  @IsString()
  @Length(8, 12)
  dateDeplacement?: string;

  @IsOptional()
  @IsString()
  @Length(4, 6)
  heureDepart?: string;
}

export class TraiterSignalementDto {
  @IsIn(['traite', 'rejete'])
  decision: 'traite' | 'rejete';

  @IsOptional()
  @IsString()
  @Length(0, 500)
  detail?: string;
}

export class PromouvoirAdminDto {
  @IsEnum(AdminRole)
  role: AdminRole;
}
