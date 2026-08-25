import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ContactUrgence } from '../contact-urgence/contact-urgence.entity';
import { UsersService } from '../users/users.service';

@Injectable()
export class ContactUrgenceService {
  constructor(
    @InjectRepository(ContactUrgence)
    private readonly contactRepository: Repository<ContactUrgence>,
    private readonly usersService: UsersService,
  ) {}

  async definir(dto: {
    userId: string;
    nomContact: string;
    telephoneContact: string;
    lien?: string;
  }): Promise<ContactUrgence> {
    const user = await this.usersService.findOne(dto.userId);
    const existant = await this.contactRepository.findOne({
      where: { user: { id: dto.userId } },
    });
    if (existant) {
      existant.nomContact = dto.nomContact.trim();
      existant.telephoneContact = dto.telephoneContact;
      existant.lien = dto.lien?.trim();
      return this.contactRepository.save(existant);
    }
    const contact = this.contactRepository.create({
      user,
      nomContact: dto.nomContact.trim(),
      telephoneContact: dto.telephoneContact,
      lien: dto.lien?.trim(),
    });
    return this.contactRepository.save(contact);
  }

  async de(userId: string): Promise<ContactUrgence | null> {
    return this.contactRepository.findOne({
      where: { user: { id: userId } },
    });
  }

  /**
   * Contact d'urgence du partenaire confirmé d'un AD.
   * Visible uniquement entre deux partenaires confirmés (jamais avant).
   */
  async contactPartenaireConfirmé(
    adId: string,
    demandeurId: string,
  ): Promise<{ nomContact: string; telephoneContact: string; lien: string | null } | null> {
    // Le contact renvoyé est celui du PROPRIÉTAIRE de l'AD, visible par le
    // demandeur dont la demande est acceptée (et inversement).
    const acceptee = await this.contactRepository.manager.query(
      `SELECT u.id FROM demandes d
       JOIN avis_deplacement a ON a."id" = d."adId"
       JOIN users u ON u."id" = a."proprietaireId"
       WHERE d."id" = $1 LIMIT 1`,
      [adId],
    );
    void acceptee;
    // Vérification simplifiée : l'AD doit avoir une demande acceptée du demandeur.
    const verif = await this.contactRepository.manager.query(
      `SELECT d."id" FROM demandes d
       WHERE d."adId" = $1 AND d."demandeurId" = $2 AND d."statut" = 'acceptee' LIMIT 1`,
      [adId, demandeurId],
    );
    if (!verif || verif.length === 0) {
      throw new NotFoundException(
        'Aucun partenariat confirmé : contact non accessible',
      );
    }
    // Le partenaire = propriétaire de l'AD.
    const ad = await this.contactRepository.manager.query(
      `SELECT u."id" FROM avis_deplacement a JOIN users u ON u."id" = a."proprietaireId" WHERE a."id" = $1`,
      [adId],
    );
    if (!ad || ad.length === 0) {
      throw new NotFoundException('AD introuvable');
    }
    const contact = await this.contactRepository.findOne({
      where: { user: { id: ad[0].id } },
    });
    if (!contact) return null;
    return {
      nomContact: contact.nomContact,
      telephoneContact: contact.telephoneContact,
      lien: contact.lien,
    };
  }
}
