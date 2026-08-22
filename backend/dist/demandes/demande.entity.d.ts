import { User } from '../users/user.entity';
import { AvisDeplacement } from '../ads/avis-deplacement.entity';
export declare enum StatutDemande {
    EN_ATTENTE = "en_attente",
    ACCEPTEE = "acceptee",
    REFUSEE = "refusee",
    ANNULEE = "annulee"
}
export declare class Demande {
    id: string;
    ad: AvisDeplacement;
    demandeur: User;
    statut: StatutDemande;
    creeLe: Date;
}
