// src/auth/auth.module.ts
import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { UsersModule } from '../users/users.module';
import { PassportModule } from '@nestjs/passport';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { LocalStrategy } from './strategies/local.strategy'; // Importado

@Module({
  imports: [
    UsersModule,
    PassportModule,
    ConfigModule, // Se estiver usando ConfigService para JWT
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: async (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: {
          expiresIn: configService.get<string>('JWT_EXPIRATION_TIME'),
        },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,     // 👈 AuthService está aqui
    LocalStrategy    // 👈 LocalStrategy está aqui
  ],
  exports: [AuthService, JwtModule], // AuthService é exportado (para JWTStrategy depois, ou se outro módulo precisar)
})
export class AuthModule {}