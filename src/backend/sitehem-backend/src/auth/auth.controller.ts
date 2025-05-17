// src/auth/auth.controller.ts
import { Controller, Post, Body, UseGuards, Request } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginAuthDto } from './dto/login-auth.dto';
import { AuthGuard } from '@nestjs/passport'; // Para usar AuthGuard('local')

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @UseGuards(AuthGuard('local')) // Ativa a LocalStrategy
  @Post('login')
  async login(@Request() req, @Body() loginAuthDto: LoginAuthDto /* DTO para validação do corpo */) {
    // Se chegou aqui, LocalStrategy.validate() foi bem-sucedido e req.user está populado.
    // O loginAuthDto aqui é mais para o Swagger e validação de corpo,
    // a validação real de credenciais foi feita pela LocalStrategy.
    return this.authService.login(req.user);
  }
}