import { IsInt, IsNotEmpty } from 'class-validator';

export class AssignRoleDto {
  @IsNotEmpty({ message: 'O ID do perfil não pode ser vazio.' })
  @IsInt({ message: 'O ID do perfil deve ser um número inteiro.' })
  roleId: number;
}
