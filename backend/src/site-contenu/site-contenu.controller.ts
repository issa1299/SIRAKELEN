import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { IsBoolean, IsInt, IsOptional, IsString, Length } from 'class-validator';
import { SiteContenuService } from './site-contenu.service';
import { AdminService } from '../admin/admin.service';
import { AdminGuard } from '../admin/admin.guard';
import { Permissions } from '../admin/permissions.decorator';
import { AdminPermission } from '../admin/admin-role.enum';
import { AdminActuel } from '../admin/admin.decorator';
import { AdminTokenPayload } from '../admin/admin-auth.service';

class ValeurDto {
  @IsString()
  @Length(0, 10000)
  valeur: string;

  @IsOptional()
  @IsString()
  @Length(0, 40)
  groupe?: string;

  @IsOptional()
  @IsString()
  @Length(0, 20)
  type?: string;
}

class NewsDto {
  @IsString()
  @Length(1, 200)
  titre: string;

  @IsString()
  @Length(1, 10000)
  contenu: string;

  @IsOptional()
  @IsString()
  @Length(0, 500)
  imageUrl?: string;

  @IsOptional()
  @IsString()
  datePublication?: string;

  @IsOptional()
  @IsBoolean()
  actif?: boolean;
}

class FaqDto {
  @IsString()
  @Length(1, 300)
  question: string;

  @IsString()
  @Length(1, 5000)
  reponse: string;

  @IsOptional()
  @IsInt()
  ordre?: number;

  @IsOptional()
  @IsBoolean()
  actif?: boolean;
}

@Controller()
export class SiteContenuController {
  constructor(
    private readonly service: SiteContenuService,
    private readonly adminService: AdminService,
  ) {}

  private id(admin: AdminTokenPayload) {
    return { id: admin.adminId, prenom: admin.prenom || 'Administrateur' };
  }

  // ---------- Public ----------

  @Get('site/contenu')
  public() {
    return this.service.public();
  }

  // ---------- Textes / images / liens ----------

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.CONTENU_LIRE)
  @Get('admin/site/contenu')
  listeContenu(@Query('groupe') groupe?: string) {
    return this.service.findContenu(groupe);
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.CONTENU_MODIFIER)
  @Patch('admin/site/contenu/:cle')
  async setContenu(
    @Param('cle') cle: string,
    @Body() dto: ValeurDto,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    const a = this.id(admin);
    const resultat = await this.service.setContenu(
      cle,
      dto.valeur,
      dto.groupe || 'general',
      dto.type || 'texte',
      a.id,
    );
    await this.adminService.journal(a.id, a.prenom, 'CONTENU_MODIFIE', 'SiteContenu', resultat.id, cle);
    return resultat;
  }

  // ---------- Paramètres généraux ----------

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.PARAMETRES_MODIFIER)
  @Get('admin/parametres')
  parametres() {
    return this.service.findContenu('parametre');
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.PARAMETRES_MODIFIER)
  @Patch('admin/parametres/:cle')
  async setParametre(
    @Param('cle') cle: string,
    @Body() dto: ValeurDto,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    const a = this.id(admin);
    const resultat = await this.service.setContenu(cle, dto.valeur, 'parametre', dto.type || 'texte', a.id);
    await this.adminService.journal(a.id, a.prenom, 'PARAMETRE_MODIFIE', 'Parametre', resultat.id, cle);
    return resultat;
  }

  // ---------- Actualités ----------

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.CONTENU_LIRE)
  @Get('admin/site/news')
  news() {
    return this.service.findNews();
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.CONTENU_MODIFIER)
  @Post('admin/site/news')
  async creerNews(@Body() dto: NewsDto, @AdminActuel() admin: AdminTokenPayload) {
    const a = this.id(admin);
    const news = await this.service.creerNews(dto);
    await this.adminService.journal(a.id, a.prenom, 'ACTUALITE_CREE', 'SiteNews', news.id, news.titre);
    return news;
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.CONTENU_MODIFIER)
  @Patch('admin/site/news/:id')
  async modifierNews(
    @Param('id') id: string,
    @Body() dto: NewsDto,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    const a = this.id(admin);
    const news = await this.service.modifierNews(id, dto as any);
    await this.adminService.journal(a.id, a.prenom, 'ACTUALITE_MODIFIEE', 'SiteNews', id, news.titre);
    return news;
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.CONTENU_MODIFIER)
  @Delete('admin/site/news/:id')
  async supprimerNews(
    @Param('id') id: string,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    const a = this.id(admin);
    await this.service.supprimerNews(id);
    await this.adminService.journal(a.id, a.prenom, 'ACTUALITE_SUPPRIMEE', 'SiteNews', id, null);
    return { supprime: true };
  }

  // ---------- FAQ ----------

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.CONTENU_LIRE)
  @Get('admin/site/faq')
  faq() {
    return this.service.findFaq();
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.CONTENU_MODIFIER)
  @Post('admin/site/faq')
  async creerFaq(@Body() dto: FaqDto, @AdminActuel() admin: AdminTokenPayload) {
    const a = this.id(admin);
    const faq = await this.service.creerFaq(dto);
    await this.adminService.journal(a.id, a.prenom, 'FAQ_CREE', 'SiteFaq', faq.id, faq.question);
    return faq;
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.CONTENU_MODIFIER)
  @Patch('admin/site/faq/:id')
  async modifierFaq(
    @Param('id') id: string,
    @Body() dto: FaqDto,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    const a = this.id(admin);
    const faq = await this.service.modifierFaq(id, dto as any);
    await this.adminService.journal(a.id, a.prenom, 'FAQ_MODIFIEE', 'SiteFaq', id, faq.question);
    return faq;
  }

  @UseGuards(AdminGuard)
  @Permissions(AdminPermission.CONTENU_MODIFIER)
  @Delete('admin/site/faq/:id')
  async supprimerFaq(
    @Param('id') id: string,
    @AdminActuel() admin: AdminTokenPayload,
  ) {
    const a = this.id(admin);
    await this.service.supprimerFaq(id);
    await this.adminService.journal(a.id, a.prenom, 'FAQ_SUPPRIMEE', 'SiteFaq', id, null);
    return { supprime: true };
  }
}
