import { User } from '../users/user.entity';
export declare enum StatutSignalement {
    EN_ATTENTE = "en_attente",
    TRAITE = "traite"
}
export declare class Signalement {
    id: string;
    utilisateurSignale: User;
    auteur: User;
    motif: string;
    statut: StatutSignalement;
    creeLe: Date;
}
