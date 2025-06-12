   // src/auth/strategies/jwt.strategy.ts
   import { Injectable, UnauthorizedException, InternalServerErrorException } from '@nestjs/common';
   import { PassportStrategy } from '@nestjs/passport';
   import { ExtractJwt, Strategy } from 'passport-jwt';
   import { ConfigService } from '@nestjs/config';
   import { UsersService } from '../../users/users.service';
   // Importe o tipo UserRole e Role se quiser tipar os perfis de forma mais explícita
   // import { UserRole, Role } from '@prisma/client';

   @Injectable()
   export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
     constructor(
       private readonly configService: ConfigService,
       private readonly usersService: UsersService, // UsersService já deve buscar perfis com findOne
     ) {
       let jwtSecret: string;
       try {
         jwtSecret = configService.getOrThrow<string>('JWT_SECRET');
       } catch (e) {
         console.error('Falha crítica ao carregar JWT_SECRET das variáveis de ambiente:', e.message);
         throw new InternalServerErrorException(
           'Configuração de segurança interna inválida.',
         );
       }

       super({
         jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
         ignoreExpiration: false,
         secretOrKey: jwtSecret,
       });
     }

     async validate(payload: any): Promise<any> {
       // payload: { email: user.email, sub: user.id, name: user.name }

       if (!payload || typeof payload.sub === 'undefined') {
         throw new UnauthorizedException('Token inválido ou malformado.');
       }

       // O UsersService.findOne já foi modificado para incluir os perfis (roles)
       // com a estrutura: user.roles: [{ role: { id: ..., name: ... } }, ...]
       const userWithRoles = await this.usersService.findOne(payload.sub);

       if (!userWithRoles || !userWithRoles.is_active) {
         throw new UnauthorizedException('Token inválido ou utilizador inativo/não encontrado.');
       }

       // Extrair apenas os nomes dos perfis para facilitar a verificação no Guard
       const roleNames = userWithRoles.roles.map(userRole => userRole.role.name);

       // O que é retornado aqui será anexado a request.user
       return {
         userId: payload.sub,
         email: userWithRoles.email, // Usar o email do utilizador encontrado para garantir que está atualizado
         name: userWithRoles.name,   // Usar o nome do utilizador encontrado
         roles: roleNames,           // Array de nomes de perfis, ex: ['admin', 'customer']
       };
     }
   }
   