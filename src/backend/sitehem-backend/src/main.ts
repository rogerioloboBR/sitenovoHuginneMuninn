// src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common'; // 👈 Importar ValidationPipe
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Configurar o ValidationPipe globalmente
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Remove propriedades que não estão no DTO
      forbidNonWhitelisted: true, // Lança erro se propriedades não listadas forem enviadas
      transform: true, // Transforma o payload para o tipo do DTO (ex: string para número se anotado)
    }),
  );

  // --- Configuração do Swagger (OpenAPI) ---
  const config = new DocumentBuilder() // 👈 2. Crie uma instância do DocumentBuilder
    .setTitle('API HeM E-commerce & Blog') // 👈 Defina o título da sua API
    .setDescription(
      'Documentação detalhada da API para o projeto de e-commerce e blog Hemb.', // 👈 Defina uma descrição
    )
    .setVersion('1.0') // 👈 Defina a versão da sua API
    .addTag('Auth', 'Operações de Autenticação') // Adiciona uma "tag" para agrupar rotas de Autenticação
    .addTag('Users', 'Operações relacionadas a Usuários') // Adiciona uma "tag" para Usuários
    // Você adicionará mais tags aqui à medida que criar novos módulos (Products, Orders, BlogPosts, etc.)
    .addBearerAuth( // 👈 3. Configuração para autenticação JWT (Bearer Token)
      {
        type: 'http', // Tipo de esquema de segurança
        scheme: 'bearer', // Esquema (bearer para JWT)
        bearerFormat: 'JWT', // Formato do token
        name: 'JWT', // Nome da definição de segurança
        description: 'Insira o token JWT', // Descrição para a UI
        in: 'header', // Onde o token é esperado (no header Authorization)
      },
      'access-token', // Este é um nome/chave para esta definição de segurança. Usaremos em @ApiBearerAuth() nos controllers.
    )
    .build(); // 👈 4. Constrói o objeto de configuração

  const document = SwaggerModule.createDocument(app, config); // 👈 5. Cria o documento OpenAPI
  SwaggerModule.setup('api-docs', app, document); // 👈 6. Configura o endpoint para a UI do Swagger
  // A UI do Swagger estará disponível em http://localhost:3000/api-docs

  // --- Fim da Configuração do Swagger ---
  await app.listen(3000);
  console.log(`Application is running on: ${await app.getUrl()}`);
}
bootstrap();