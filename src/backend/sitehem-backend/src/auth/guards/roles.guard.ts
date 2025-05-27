// src/auth/guards/roles.guard.ts
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../decorators/roles.decorator'; // Importa a chave dos metadados
import { RoleName } from '../enums/role-name.enum'; // Importa o enum dos nomes dos perfis

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {} // Injeta o Reflector para ler metadados

  canActivate(context: ExecutionContext): boolean {
    // 1. Obtém os perfis (roles) necessários que foram definidos com o decorator @Roles() na rota
    const requiredRoles = this.reflector.getAllAndOverride<RoleName[]>(
      ROLES_KEY,
      [
        context.getHandler(), // Metadados do método da rota
        context.getClass(),   // Metadados da classe do controller
      ],
    );

    // Se nenhum perfil for necessário para a rota, permite o acesso
    // (ou seja, se o decorator @Roles() não foi usado, ou foi usado com um array vazio)
    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    // 2. Obtém o objeto 'user' da requisição (anexado pela JwtStrategy após autenticação bem-sucedida)
    const { user } = context.switchToHttp().getRequest();

    // Se não houver utilizador na requisição (ex: se o AuthGuard('jwt') não foi usado antes deste guard,
    // ou se o token for inválido e a JwtStrategy não anexou o utilizador), nega o acesso.
    // Nota: É uma boa prática garantir que o AuthGuard('jwt') sempre execute ANTES do RolesGuard.
    if (!user || !user.roles) {
      return false;
    }

    // 3. Compara os perfis necessários com os perfis que o utilizador possui
    // O utilizador precisa ter PELO MENOS UM dos perfis necessários.
    // user.roles é o array de nomes de perfis que definimos na JwtStrategy.validate()
    // ex: ['admin', 'customer']
    const hasRequiredRole = requiredRoles.some((role) =>
      user.roles.includes(role),
    );

    return hasRequiredRole;
  }
}
