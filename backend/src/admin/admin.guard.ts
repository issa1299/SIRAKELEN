import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AdminAuthService, AdminTokenPayload } from './admin-auth.service';
import { AdminPermission } from './admin-role.enum';
import { PERMISSIONS_KEY } from './permissions.decorator';

/** Guard global aux contrôleurs admin : vérifie le token + les permissions. */
@Injectable()
export class AdminGuard implements CanActivate {
  constructor(
    private readonly auth: AdminAuthService,
    private readonly reflector: Reflector,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const header = request.headers?.authorization;
    const token = this.auth.extraireToken(header);
    const payload: AdminTokenPayload = this.auth.verifierToken(token);

    // Stocker le payload pour les contrôleurs (adminId, rôle).
    request.admin = payload;

    const requises = this.reflector.getAllAndOverride<AdminPermission[]>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (requises && requises.length) {
      for (const p of requises) {
        this.auth.exigerPermission(payload, p);
      }
    }
    return true;
  }
}

export { UnauthorizedException };
