import { ContactUrgence } from '../contact-urgence/contact-urgence.entity';
import { AvisDeplacement } from '../ads/avis-deplacement.entity';
import { Demande } from '../demandes/demande.entity';
export declare class User {
    id: string;
    prenom: string;
    nom: string;
    telephone: string;
    quartier: string;
    photoUrl: string;
    verifie: boolean;
    creeLe: Date;
    contactUrgence: ContactUrgence;
    ads: AvisDeplacement[];
    demandesEnvoyees: Demande[];
}
