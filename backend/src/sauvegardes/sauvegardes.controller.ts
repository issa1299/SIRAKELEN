import { Controller, Get, Post, UseGuards } from '@nestjs/common';
import { SauvegardesService } from './sauvegardes.service';
import { AdminService } from '../admin/admin.service';
import { AdminGuard } from '../admin/admin.guard';
import { Permissions } from '../admin/permissions.decorator';
import { AdminPermission } from '../admin/admin-role.enum';
import { AdminActuel } from '../admin/admin.decorator';
import { AdminTokenPayload } from '../admin/admin-auth.service';

/** Aucun endpoint ne renvoie le contenu d'un fichier de sauvegarde. */
@Controller('admin/sauvegardes')
@UseGuards(AdminGuard)
export class SauvegardesController {
  constructor(
    private readonly service: SauvegardesService,
    private readonly adminService: AdminService,
  ) {}

  @Get()
  @Permissions(AdminPermission.SAUVEGARDES)
  etat() {
    return this.service.etat();
  }

  @Post()
  @Permissions(AdminPermission.SAUVEGARDES)
  async lancer(@AdminActuel() admin: AdminTokenPayload) {
    const resultat = await this.service.lancer();
    await this.adminService.journal(
      admin.adminId,
      admin.prenom || 'Administrateur',
      'SAUVEGARDE_LANCEE',
      'Sauvegarde',
      resultat.nom,
      `${resultat.tailleOctets} octets`,
    );
    return resultat;
  }
}
