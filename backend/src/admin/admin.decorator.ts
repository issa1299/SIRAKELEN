import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { AdminTokenPayload } from './admin-auth.service';

/** Injecte les informations de l'administrateur authentifié (issues du token vérifié). */
export const AdminActuel = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AdminTokenPayload => {
    const request = ctx.switchToHttp().getRequest();
    return request.admin as AdminTokenPayload;
  },
);
