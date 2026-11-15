import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export type TriParcourir = 'pertinence' | 'date';

/**
 * Parametres de GET /ads/parcourir/:userId.
 * Filtres maximum 4 : date/plage horaire, zone de depart, zone d'arrivee, transport.
 * Le prefiltrage par defaut (date + zone de l'AD de l'utilisateur) est supprime
 * quand elargir = true.
 */
export class ListerAdsDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'Page invalide' })
  @Min(1)
  page = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt({ message: 'Limite invalide' })
  @Min(1)
  @Max(50, { message: 'Limite max 50' })
  limite = 20;

  @IsOptional()
  @IsIn(['pertinence', 'date'], { message: 'Tri invalide' })
  tri: TriParcourir = 'pertinence';

  /** Filtre 1 : date de deplacement (YYYY-MM-DD). */
  @IsOptional()
  @IsDateString({}, { message: 'Date invalide' })
  date?: string;

  /** Filtre 1 : plage horaire (borne basse HH:mm). */
  @IsOptional()
  @Matches(/^([01][0-9]|2[0-3]):[0-5][0-9]$/, {
    message: 'Heure invalide (format HH:mm)',
  })
  heureDebut?: string;

  /** Filtre 1 : plage horaire (borne haute HH:mm). */
  @IsOptional()
  @Matches(/^([01][0-9]|2[0-3]):[0-5][0-9]$/, {
    message: 'Heure invalide (format HH:mm)',
  })
  heureFin?: string;

  /** Filtre 2 : zone / quartier de depart. */
  @IsOptional()
  @IsString()
  @MaxLength(150)
  zoneDepart?: string;

  /** Filtre 3 : zone / quartier d'arrivee. */
  @IsOptional()
  @IsString()
  @MaxLength(150)
  zoneArrivee?: string;

  /** Filtre 4 : type de transport. */
  @IsOptional()
  @IsString()
  @MaxLength(40)
  transport?: string;

  /**
   * Elargir la recherche : supprime le prefiltrage par defaut
   * (date + zone de l'AD de l'utilisateur).
   */
  @IsOptional()
  @Transform(({ value }) => value === true || value === 'true')
  @IsBoolean()
  elargir = false;
}
