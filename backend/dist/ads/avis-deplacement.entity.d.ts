import { User } from '../users/user.entity';
export declare enum RoleAd {
    CONDUCTEUR = "conducteur",
    PASSAGER = "passager"
}
export declare enum StatutAd {
    ACTIF = "actif",
    EN_COURS_DE_FINALISATION = "en_cours_de_finalisation",
    TRAJET_ORGANISE = "trajet_organise",
    ANNULE = "annule"
}
export declare class AvisDeplacement {
    id: string;
    proprietaire: User;
    role: RoleAd;
    depart: string;
    destination: string;
    dateDeplacement: string;
    heureDepart: string;
    moyenTransport: string;
    placesDisponibles: number;
    statut: StatutAd;
    creeLe: Date;
}
