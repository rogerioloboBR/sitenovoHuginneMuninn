// src/permissions/dto/create-permission.dto.ts
import {
    IsNotEmpty,
    IsOptional,
    IsString,
    MaxLength,
  } from 'class-validator';
  
  export class CreatePermissionDto {
    @IsNotEmpty({ message: 'O nome da permissão não pode ser vazio.' })
    @IsString({ message: 'O nome da permissão deve ser uma string.' })
    @MaxLength(100, {
      message: 'O nome da permissão deve ter no máximo 100 caracteres.',
    })
    name: string; // Ex: "products.create", "users.view_all"
  
    @IsOptional()
    @IsString({ message: 'A descrição deve ser uma string.' })
    @MaxLength(255, {
      message: 'A descrição deve ter no máximo 255 caracteres.',
    })
    description?: string;
  
    @IsOptional()
    @IsString({ message: 'O nome do grupo deve ser uma string.' })
    @MaxLength(50, {
      message: 'O nome do grupo deve ter no máximo 50 caracteres.',
    })
    group_name?: string; // Ex: "Produtos", "Usuários"
  }