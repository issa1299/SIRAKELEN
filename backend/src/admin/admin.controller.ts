import { Controller, Get, Post, Patch, Body } from '@nestjs/common';
import { AdminService } from './admin.service';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Post('login')
  login(@Body() body: { email: string; motDePasse: string }) {
    return this.adminService.login(body.email, body.motDePasse);
  }

  @Patch('profil')
  profil(@Body() body: { id: string; prenom?: string; nom?: string }) {
    return this.adminService.updateProfil(body.id, body.prenom, body.nom);
  }

  @Post('mot-de-passe')
  motDePasse(
    @Body() body: { id: string; ancien: string; nouveau: string },
  ) {
    return this.adminService.changerMotDePasse(
      body.id,
      body.ancien,
      body.nouveau,
    );
  }

  @Get('stats')
  stats() {
    return this.adminService.stats();
  }

  @Get('users')
  users() {
    return this.adminService.findAllUsers();
  }

  @Get('ads')
  ads() {
    return this.adminService.findAllAds();
  }

  @Get('signalements')
  signalements() {
    return this.adminService.findAllSignalements();
  }
}
