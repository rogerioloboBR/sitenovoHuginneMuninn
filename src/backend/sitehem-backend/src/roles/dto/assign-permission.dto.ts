// src/roles/dto/assign-permission.dto.ts
import { IsInt, IsNotEmpty } from 'class-validator';
export class AssignPermissionDto {
  @IsNotEmpty({ message: 'O ID da permissão não pode ser vazio.'})
  @IsInt({ message: 'O ID da permissão deve ser um número inteiro.'})
  permissionId: number;
}