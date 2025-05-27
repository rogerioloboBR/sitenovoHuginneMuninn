import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateRoleDto } from './dto/create-role.dto';
import { UpdateRoleDto } from './dto/update-role.dto';
import { Role, Permission } from '@prisma/client'; // RolePermission também pode ser importado se você for tipar retornos mais especificamente
import { PermissionsService } from '../permissions/permissions.service'; // Certifique-se que o caminho está correto

@Injectable()
export class RolesService {
  constructor(
    private prisma: PrismaService,
    private permissionsService: PermissionsService, // Injetando o PermissionsService
  ) {}

  async create(createRoleDto: CreateRoleDto): Promise<Role> {
    const existingRole = await this.prisma.role.findUnique({
      where: { name: createRoleDto.name },
    });

    if (existingRole) {
      throw new ConflictException(
        `Um perfil com o nome '${createRoleDto.name}' já existe.`,
      );
    }

    return this.prisma.role.create({
      data: createRoleDto,
    });
  }

  async findAll(): Promise<Role[]> {
    // Modificado para incluir as permissões associadas
    return this.prisma.role.findMany({
      include: {
        permissions: { // Inclui as entradas da tabela de junção RolePermission
          include: {
            permission: true, // Dentro de cada RolePermission, inclui o objeto Permission completo
          },
        },
      },
    });
  }

  async findOne(id: number): Promise<Role> {
    // Modificado para incluir as permissões associadas
    const role = await this.prisma.role.findUnique({
      where: { id },
      include: {
        permissions: {
          include: {
            permission: true,
          },
        },
      },
    });

    if (!role) {
      throw new NotFoundException(`Perfil com ID #${id} não encontrado.`);
    }
    return role;
  }

  async update(id: number, updateRoleDto: UpdateRoleDto): Promise<Role> {
    const roleToUpdate = await this.prisma.role.findUnique({ where: { id } });
    if (!roleToUpdate) {
      throw new NotFoundException(
        `Perfil com ID #${id} não encontrado para atualização.`,
      );
    }

    if (updateRoleDto.name && updateRoleDto.name !== roleToUpdate.name) {
      const existingRoleWithNewName = await this.prisma.role.findUnique({
        where: { name: updateRoleDto.name },
      });
      if (existingRoleWithNewName && existingRoleWithNewName.id !== id) {
        throw new ConflictException(
          `Um perfil com o nome '${updateRoleDto.name}' já existe.`,
        );
      }
    }

    return this.prisma.role.update({
      where: { id },
      data: updateRoleDto,
    });
  }

  async remove(id: number): Promise<Role> {
    const roleExists = await this.prisma.role.findUnique({ where: { id } });
    if (!roleExists) {
      throw new NotFoundException(
        `Perfil com ID #${id} não encontrado para exclusão.`,
      );
    }
    // O onDelete: Cascade na relação Role -> RolePermission no schema.prisma
    // deve cuidar da remoção das associações em role_permissions.
    return this.prisma.role.delete({
      where: { id },
    });
  }

  // --- NOVOS MÉTODOS PARA ASSOCIAÇÃO DE PERMISSÕES ---

  async assignPermissionToRole(roleId: number, permissionId: number) {
    // 1. Verificar se o Role existe
    // Usamos o findOne deste próprio service, que já lança NotFoundException
    await this.findOne(roleId);

    // 2. Verificar se a Permission existe
    // Usamos o findOne do PermissionsService injetado
    await this.permissionsService.findOne(permissionId); // Lançará NotFoundException se não existir

    // 3. Verificar se a associação já existe para evitar erro de chave duplicada
    const existingAssociation = await this.prisma.rolePermission.findUnique({
      where: {
        role_id_permission_id: { // Nome do índice/chave primária composta no schema.prisma
          role_id: roleId,
          permission_id: permissionId,
        },
      },
    });

    if (existingAssociation) {
      throw new ConflictException(
        'Esta permissão já está atribuída a este perfil.',
      );
    }

    // 4. Criar a associação na tabela role_permissions
    return this.prisma.rolePermission.create({
      data: {
        role_id: roleId,
        permission_id: permissionId,
      },
      include: { // Opcional: retornar dados relacionados para confirmação
        role: true,
        permission: true,
      },
    });
  }

  async removePermissionFromRole(roleId: number, permissionId: number) {
    // 1. Verificar se a associação existe antes de tentar deletar
    const association = await this.prisma.rolePermission.findUnique({
      where: {
        role_id_permission_id: {
          role_id: roleId,
          permission_id: permissionId,
        },
      },
    });

    if (!association) {
      throw new NotFoundException(
        'Associação entre este perfil e permissão não encontrada para remoção.',
      );
    }

    // 2. Remover a associação
    return this.prisma.rolePermission.delete({
      where: {
        role_id_permission_id: {
          role_id: roleId,
          permission_id: permissionId,
        },
      },
    });
  }

  async findPermissionsForRole(roleId: number): Promise<Permission[]> {
    // 1. Verificar se o Role existe
    await this.findOne(roleId); // Reutiliza o findOne, que já inclui as permissões

    // 2. Buscar as associações e as permissões relacionadas
    // O findOne já foi modificado para incluir isso, mas se quiséssemos ser mais explícitos
    // ou se findOne não incluísse, faríamos:
    const roleWithPermissions = await this.prisma.role.findUnique({
      where: { id: roleId },
      include: {
        permissions: { // Inclui as entradas da tabela de junção RolePermission
          include: {
            permission: true, // Dentro de cada RolePermission, inclui o objeto Permission completo
          },
        },
      },
    });

    if (!roleWithPermissions) {
        // Embora findOne já verifique, uma dupla checagem não faz mal ou
        // esta lógica seria usada se findOne não fizesse a inclusão.
        throw new NotFoundException(`Perfil com ID #${roleId} não encontrado.`);
    }

    // 3. Mapear para retornar apenas a lista de objetos Permission
    return roleWithPermissions.permissions.map((rp) => rp.permission);
  }
}