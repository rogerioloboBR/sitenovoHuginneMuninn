// src/auth/decorators/roles.decorator.ts
import { SetMetadata } from '@nestjs/common';
import { RoleName } from '../enums/role-name.enum'; // Vamos criar este enum a seguir

export const ROLES_KEY = 'roles'; // Chave para armazenar os metadados dos perfis

// O decorator @Roles() aceita um array de nomes de perfis (RoleName)
// e associa esses nomes como metadados à rota ou controller onde for usado.
export const Roles = (...roles: RoleName[]) => SetMetadata(ROLES_KEY, roles);
