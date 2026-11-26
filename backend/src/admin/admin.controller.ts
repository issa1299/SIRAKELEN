import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AdminService } from './admin.service';
import { AdminTokenPayload } from './admin-auth.service';
import { AdminGuard } from './admin.guard';
import { AdminActuel } from './admin.decorator';
import { Permissions } from './permissions.decorator';
import { AdminPermission, AdminRole, ROLE_PERMISSIONS } from './admin-role.enum';
import { StatutUtilisateur } from '../users/user.entity';
import { StatutAd } from '../ads/avis-deplacement.entity';
import { StatutSignalement } from '../signalements/signalement.entity';
import {
  ChangerMotDePasseDto,
  LoginAdminDto,
  ModifierAdDto,
  ModifierStatutAdDto,
  PromouvoirAdminDto,
  SuspendreUserDto,
  TraiterSignalementDto,
  UpdateProfilDto,
  UpdateUserAdminDto,
} from './dto/admin.dto';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  private identite(admin: AdminTokenPayload) {
    return { id: admin.adminId, prenom: admin.prenom || 'Administrateur' };
  }

  // ================================================================
  // Authentification (route publique)
  // ================================================================

  @Post('login')
  login(@Body() dto: LoginAdminDto) {
    return this.adminService.login(dto.email, dto.motDePasse);
  }

  /** Vérifie le token et renvoie le profil de l'administrateur connecté. */
  @UseGuards(AdminGuard)
  @Get('moi')
  moi(@AdminActuel() admin: AdminTokenPayload) {
    return {
      id: admin.adminId,
      role: admin.role,
      prenom: admin.prenom,
      permissions: ROLE_PERMISSIONS[admin.role] || [],
    };
  }

  @UseGuards(AdminGuard)
  @Patch('profil')
  profil(@AdminActuel() admin: AdminTokenPayload, @Body() dto: UpdateProfilDto) {
    return this.adminService.updateProfil(admin.adminId, dto.prenom, dto.nom);
  }

  @UseGuards(AdminGuard)
  @Post('mot-de-passe')
  @HttpCode(200)
  motDePasse(
    @AdminActuel() admin: AdminTokenPayload,
    @Body() dto: ChangerMotDePasseDto,
  ) {
    return this.adminService.changerMotDePasse(
      admin.adminId,
      dto.ancien,
      dto.nouveau,
    );
  }

  // ================================================================
  // Tableau de bord
  // ================================================================

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.STATS_LIRE)
  @Get('stats')
  stats() {
    return this.adminService.stats();
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.STATS_LIRE)
  @Get('activite')
  activite() {
    return this.adminService.activiteRecente();
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.JOURNAL_LIRE)
  @Get('logs')
  logs(@Query('limite') limite?: string) {
    return this.adminService.findLogs(limite ? parseInt(limite, 10) : 100);
  }

  // ================================================================
  // Utilisateurs
  // ================================================================

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.USERS_LIRE)
  @Get('users')
  users(
    @Query('q') q?: string,
    @Query('statut') statut?: StatutUtilisateur,
    @Query('admin') adminParam?: string,
  ) {
    return this.adminService.findAllUsers({
      q,
      statut,
      admin: adminParam === undefined ? undefined : adminParam === 'true',
    });
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.USERS_LIRE)
  @Get('users/:id')
  user(@Param('id', ParseUUIDPipe) id: string) {
    return this.adminService.findUser(id);
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.USERS_MODIFIER)
  @Patch('users/:id')
  updateUser(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserAdminDto,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    const resultat = this.adminService.updateUser(id, dto);
    this.adminService
      .journal(this.identite(admin).id, this.identite(admin).prenom, 'UTILISATEUR_MODIFIE', 'User', id, JSON.stringify(dto))
      .catch(() => undefined);
    return resultat;
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.USERS_SUSPENDRE)
  @Post('users/:id/suspendre')
  suspendreUser(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SuspendreUserDto,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    return this.adminService.suspendreUser(
      id,
      dto.statut,
      dto.motif || '',
      this.identite(admin),
    );
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.USERS_SUSPENDRE)
  @Post('users/:id/reactiver')
  reactiverUser(
    @Param('id', ParseUUIDPipe) id: string,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    return this.adminService.reactiverUser(id, this.identite(admin));
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.USERS_LIRE)
  @Get('users/:id/signalements')
  signalementsUser(@Param('id', ParseUUIDPipe) id: string) {
    return this.adminService.signalementsUtilisateur(id);
  }

  // ================================================================
  // Annonces / trajets
  // ================================================================

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.ADS_LIRE)
  @Get('ads')
  ads(@Query('q') q?: string, @Query('statut') statut?: StatutAd) {
    return this.adminService.findAllAds({ q, statut });
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.USERS_SUPPRIMER)
  @Delete('users/:id')
  supprimerUser(
    @Param('id', ParseUUIDPipe) id: string,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    return this.adminService.supprimerUser(id, this.identite(admin));
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.ADS_MODIFIER)
  @Patch('ads/:id')
  modifierAd(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ModifierAdDto,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    return this.adminService.modifierAd(id, dto, this.identite(admin));
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.ADS_MODIFIER)
  @Patch('ads/:id/statut')
  modifierStatutAd(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ModifierStatutAdDto,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    return this.adminService.modifierStatutAd(id, dto.statut, this.identite(admin));
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.ADS_SUPPRIMER)
  @Delete('ads/:id')
  supprimerAd(
    @Param('id', ParseUUIDPipe) id: string,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    return this.adminService.supprimerAd(id, this.identite(admin));
  }

  // ================================================================
  // Signalements
  // ================================================================

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.SIGNALEMENTS_LIRE)
  @Get('signalements')
  signalements(@Query('statut') statut?: StatutSignalement) {
    return this.adminService.findAllSignalements({ statut });
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.SIGNALEMENTS_TRAITER)
  @Post('signalements/:id/traiter')
  traiterSignalement(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: TraiterSignalementDto,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    return this.adminService.traiterSignalement(
      id,
      dto.decision,
      dto.detail || '',
      this.identite(admin),
    );
  }

  // ================================================================
  // Demandes
  // ================================================================

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.ADS_LIRE)
  @Get('demandes')
  demandes() {
    return this.adminService.findAllDemandes();
  }

  // ================================================================
  // Gestion des administrateurs (super admin uniquement)
  // ================================================================

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.ADMINS_GERER)
  @Get('admins')
  admins() {
    return this.adminService.findAllAdmins();
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.ADMINS_GERER)
  @Post('admins/:id/promouvoir')
  promouvoir(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: PromouvoirAdminDto,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    return this.adminService.promouvoirAdmin(id, dto.role, this.identite(admin));
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.ADMINS_GERER)
  @Post('admins/:id/revoquer')
  revoquer(
    @Param('id', ParseUUIDPipe) id: string,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    return this.adminService.revoquerAdmin(id, this.identite(admin));
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.ADMINS_GERER)
  @Get('roles')
  roles() {
    return Object.values(AdminRole);
  }
}
