// src/auth/auth.service.ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  async validateUser(email: string, pass: string): Promise<any> {
    // Nota: O UsersService.findOne agora retorna o usuário SEM a senha.
    // Precisamos de um método no UsersService que retorne o usuário COM a senha para validação.
    // Vamos ajustar isso em breve. Por agora, vamos assumir que temos o usuário com senha.

    // Para este passo, vamos precisar de um método em UsersService que busque por email e inclua a senha.
    // Ex: this.usersService.findOneByEmailWithPassword(email)
    // Por enquanto, vamos simular.
    const user = await this.usersService.findOneByEmailForAuth(email); // Precisaremos criar este método

    if (user && (await bcrypt.compare(pass, user.password))) {
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const { password, ...result } = user;
      return result; // Retorna o usuário sem a senha
    }
    return null; // Ou throw new UnauthorizedException() direto aqui
  }

  async login(user: any) {
    // 'user' aqui já é o usuário validado (sem a senha), retornado pelo validate da LocalStrategy
    const payload = { email: user.email, sub: user.id, name: user.name /* adicione roles aqui depois */ };
    return {
      access_token: this.jwtService.sign(payload),
    };
  }
}