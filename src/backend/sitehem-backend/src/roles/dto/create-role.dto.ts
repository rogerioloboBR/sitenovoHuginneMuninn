import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateRoleDto {
  @IsNotEmpty({ message: 'O nome do perfil não pode ser vazio.' })
  @IsString({ message: 'O nome do perfil deve ser uma string.' })
  @MaxLength(50, { message: 'O nome do perfil deve ter no máximo 50 caracteres.' })
  name: string;

  @IsOptional() // Torna o campo descrição opcional
  @IsString({ message: 'A descrição deve ser uma string.' })
  @MaxLength(255, { message: 'A descrição deve ter no máximo 255 caracteres.' })
  description?: string; // O '?' também indica que é opcional no TypeScript
}