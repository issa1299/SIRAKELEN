import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { VersionsService } from './versions.service';
import { Plateforme } from './app-version.entity';
import { CreerVersionDto, ModifierVersionDto } from './dto/version.dto';
import { AdminService } from '../admin/admin.service';
import { AdminGuard } from '../admin/admin.guard';
import { Permissions } from '../admin/permissions.decorator';
import { AdminPermission } from '../admin/admin-role.enum';
import { AdminActuel } from '../admin/admin.decorator';
import { AdminTokenPayload } from '../admin/admin-auth.service';

@Controller('versions')
export class VersionsController {
  constructor(
    private readonly versionsService: VersionsService,
    private readonly adminService: AdminService,
  ) {}

  private identite(admin: AdminTokenPayload) {
    return { id: admin.adminId, prenom: admin.prenom || 'Administrateur' };
  }

  /** Endpoint public : dernière version active pour une plateforme. */
  @Get('latest')
  latest(@Query('plateforme') plateforme: string) {
    const p = String(plateforme || '').toLowerCase();
    if (p !== Plateforme.ANDROID && p !== Plateforme.WEB) {
      return null;
    }
    return this.versionsService.derniere(p as Plateforme);
  }

  /** Administration : liste de toutes les versions. */
  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.VERSIONS_LIRE)
  @Get('all')
  all() {
    return this.versionsService.findAll();
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.VERSIONS_LIRE)
  @Get(':id')
  one(@Param('id', ParseUUIDPipe) id: string) {
    return this.versionsService.findOne(id);
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.VERSIONS_PUBLIER)
  @Post()
  async creer(
    @Body() dto: CreerVersionDto,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    const version = await this.versionsService.creer(dto);
    const id = this.identite(admin);
    await this.adminService.journal(
      id.id,
      id.prenom,
      'VERSION_BROUILLON_CREE',
      'AppVersion',
      version.id,
      `${version.version} (${version.plateforme})`,
    );
    return version;
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.VERSIONS_PUBLIER)
  @Post(':id/publier')
  async publier(
    @Param('id', ParseUUIDPipe) id: string,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    const version = await this.versionsService.publier(id);
    const a = this.identite(admin);
    await this.adminService.journal(
      a.id,
      a.prenom,
      'VERSION_PUBLIE',
      'AppVersion',
      id,
      `${version.version} (${version.plateforme})`,
    );
    return version;
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.VERSIONS_PUBLIER)
  @Post(':id/desactiver')
  async desactiver(
    @Param('id', ParseUUIDPipe) id: string,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    const version = await this.versionsService.desactiver(id);
    const a = this.identite(admin);
    await this.adminService.journal(
      a.id,
      a.prenom,
      'VERSION_DESACTIVEE',
      'AppVersion',
      id,
      `${version.version} (${version.plateforme})`,
    );
    return version;
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.VERSIONS_PUBLIER)
  @Patch(':id')
  async modifier(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ModifierVersionDto,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    const version = await this.versionsService.modifier(id, dto);
    const a = this.identite(admin);
    await this.adminService.journal(
      a.id,
      a.prenom,
      'VERSION_MODIFIEE',
      'AppVersion',
      id,
      JSON.stringify(dto),
    );
    return version;
  }
}
