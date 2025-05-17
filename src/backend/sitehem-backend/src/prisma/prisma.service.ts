// src/prisma/prisma.service.ts
import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor() {
    super({
      // Opcional: descomente para ver logs das queries no console durante o desenvolvimento
      // log: ['query', 'info', 'warn', 'error'],
    });
  }

  async onModuleInit() {
    // O Prisma Client normalmente gerencia conexões sob demanda (lazy connecting).
    // No entanto, $connect() pode ser chamado para estabelecer uma conexão explicitamente
    // se necessário ao iniciar o módulo, ou para verificar a conectividade.
    try {
      await this.$connect();
      console.log('Successfully connected to the database (Prisma).');
    } catch (error) {
      console.error('Failed to connect to the database (Prisma).', error);
      // Você pode querer lançar o erro aqui ou lidar com ele de outra forma
      // dependendo da sua estratégia de inicialização da aplicação.
    }
  }

  async onModuleDestroy() {
    // Chamado quando a aplicação NestJS está desligando
    await this.$disconnect();
    console.log('Prisma disconnected from the database.');
  }
}