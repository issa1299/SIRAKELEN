import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { IsEnum, IsIn, IsOptional, IsString, Length } from 'class-validator';
import { NotificationsService } from './notifications.service';
import {
  CibleNotification,
  GroupeNotification,
} from './notification.entity';
import { AdminService } from '../admin/admin.service';
import { AdminGuard } from '../admin/admin.guard';
import { Permissions } from '../admin/permissions.decorator';
import { AdminPermission } from '../admin/admin-role.enum';
import { AdminActuel } from '../admin/admin.decorator';
import { AdminTokenPayload } from '../admin/admin-auth.service';

class CreerNotificationDto {
  @IsString()
  @Length(1, 120)
  titre: string;

  @IsString()
  @Length(1, 2000)
  corps: string;

  @IsEnum(CibleNotification)
  cible: CibleNotification;

  @IsOptional()
  @IsString()
  @Length(0, 100)
  cibleValeur?: string;

  @IsOptional()
  @IsString()
  dateProgramme?: string;
}

class TokenDto {
  @IsString()
  @Length(1, 100)
  userId: string;

  @IsString()
  @Length(1, 2048)
  token: string;

  @IsOptional()
  @IsIn(['android', 'web'])
  plateforme?: string;
}

@Controller()
export class NotificationsController {
  constructor(
    private readonly service: NotificationsService,
    private readonly adminService: AdminService,
  ) {}

  private identite(admin: AdminTokenPayload) {
    return { id: admin.adminId, prenom: admin.prenom || 'Administrateur' };
  }

  // ---------- Administration ----------

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.NOTIFICATIONS_LIRE)
  @Get('admin/notifications')
  findAll() {
    return this.service.findAll();
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.NOTIFICATIONS_LIRE)
  @Get('admin/notifications/fcm-statut')
  fcmStatut() {
    return { configure: this.service.fcmConfigure };
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.NOTIFICATIONS_ENVOYER)
  @Post('admin/notifications')
  async creer(
    @Body() dto: CreerNotificationDto,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    const n = await this.service.creer(dto, this.identite(admin));
    const a = this.identite(admin);
    await this.adminService.journal(
      a.id,
      a.prenom,
      'NOTIFICATION_ENVOYEE',
      'Notification',
      n.id,
      `${n.titre} — cible: ${n.cible}${n.cibleValeur ? '/' + n.cibleValeur : ''}`,
    );
    return n;
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.NOTIFICATIONS_ENVOYER)
  @Post('admin/notifications/:id/envoyer')
  @HttpCode(200)
  async envoyer(
    @Param('id', ParseUUIDPipe) id: string,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    const n = await this.service.envoyer(id);
    const a = this.identite(admin);
    await this.adminService.journal(
      a.id,
      a.prenom,
      'NOTIFICATION_ENVOYEE',
      'Notification',
      id,
      `${n.titre} — ${n.resultat}`,
    );
    return n;
  }

  // ---------- Public : application ----------

  /** Enregistrement d'un token FCM par l'application (endpoint public). */
  @Post('notifications/token')
  @HttpCode(200)
  enregistrerToken(@Body() dto: TokenDto) {
    return this.service.enregistrerToken(dto);
  }

  /** Historique des notifications publiées, consultable par l'application. */
  @Get('notifications/publiees')
  publiees(@Query('limite') limite?: string) {
    return this.service.findPubliees(limite ? parseInt(limite, 10) : 50);
  }

  /** Liste des groupes ciblables (pour le formulaire admin). */
  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.NOTIFICATIONS_LIRE)
  @Get('admin/notifications/groupes')
  groupes() {
    return Object.values(GroupeNotification);
  }
}
