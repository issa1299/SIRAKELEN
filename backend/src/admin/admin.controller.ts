import { Controller, Get, Post, Body } from '@nestjs/common';
import { AdminService } from './admin.service';

@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Post('login')
  login(@Body() body: { email: string; motDePasse: string }) {
    return this.adminService.login(body.email, body.motDePasse);
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
