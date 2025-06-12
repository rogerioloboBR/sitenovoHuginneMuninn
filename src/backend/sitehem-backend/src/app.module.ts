import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { ConfigModule } from '@nestjs/config';
import { LocalStrategy } from './auth/strategies/local.strategy';
import { RolesModule } from './roles/roles.module';
import { PermissionsModule } from './permissions/permissions.module';


@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true, // Torna o ConfigModule disponível globalmente
      envFilePath: '.env', // Especifica o arquivo .env
    }), PrismaModule, UsersModule, AuthModule, RolesModule, PermissionsModule],
  controllers: [AppController],
  providers: [AppService, LocalStrategy],
})
export class AppModule {}
