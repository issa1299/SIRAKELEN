import { SetMetadata } from '@nestjs/common';
import { AdminPermission } from './admin-role.enum';

export const PERMISSIONS_KEY = 'admin_permissions';

/** Décorateur : exige une (ou plusieurs) permissions pour une route. */
export function Permissions(...permissions: AdminPermission[]) {
  return SetMetadata(PERMISSIONS_KEY, permissions);
}
