import {
  Injectable,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import * as bcrypt from 'bcrypt';
import { User } from '@prisma/client'; // Não precisamos de Role aqui diretamente, a menos que tipemos o retorno
import { RolesService } from '../roles/roles.service'; // 👈 Importar RolesService

@Injectable()
export class UsersService {
  constructor(
    private prisma: PrismaService,
    private rolesService: RolesService, // 👈 Injetar RolesService
  ) {}

  async create(createUserDto: CreateUserDto) {
    const existingUserByEmail = await this.prisma.user.findUnique({
      where: { email: createUserDto.email },
    });

    if (existingUserByEmail) {
      throw new ConflictException('Este email já está em uso.');
    }

    const saltOrRounds = 10;
    const hashedPassword = await bcrypt.hash(
      createUserDto.password,
      saltOrRounds,
    );

    const user = await this.prisma.user.create({
      data: {
        name: createUserDto.name,
        email: createUserDto.email,
        password: hashedPassword,
      },
    });

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { password, ...result } = user;
    return result;
  }

  async findAll() {
    return this.prisma.user.findMany({
      select: { // Seleciona quais campos retornar para não expor a senha
        id: true,
        name: true,
        email: true,
        email_verified_at: true,
        is_active: true,
        created_at: true,
        updated_at: true,
        roles: { // 👈 Incluir as associações de perfis (UserRole)
          include: {
            role: true, // E os detalhes de cada perfil (Role)
          },
        },
      },
    });
  }

  async findOne(id: number) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: { // Novamente, não expor a senha e incluir perfis
        id: true,
        name: true,
        email: true,
        email_verified_at: true,
        is_active: true,
        created_at: true,
        updated_at: true,
        roles: { // 👈 Incluir as associações de perfis
          include: {
            role: true, // E os detalhes de cada perfil
          },
        },
      },
    });
    if (!user) {
      throw new NotFoundException(`Usuário com ID #${id} não encontrado.`);
    }
    return user;
  }

  async findOneByEmailForAuth(email: string): Promise<User | null> {
    // Este método é usado pela AuthService e precisa retornar o usuário com senha
    const user = await this.prisma.user.findUnique({
      where: { email },
    });
    return user; // Retorna o usuário completo, incluindo o hash da senha
  }

  async update(id: number, updateUserDto: UpdateUserDto) {
    const userToUpdate = await this.prisma.user.findUnique({ where: { id } });
    if (!userToUpdate) {
      throw new NotFoundException(`Usuário com ID #${id} não encontrado para atualização.`);
    }

    if (updateUserDto.email && updateUserDto.email !== userToUpdate.email) {
      const existingUserByEmail = await this.prisma.user.findUnique({
        where: { email: updateUserDto.email },
      });
      if (existingUserByEmail && existingUserByEmail.id !== id) {
        throw new ConflictException('Este email já está em uso por outro usuário.');
      }
    }

    const dataToUpdate: any = { ...updateUserDto };

    if (updateUserDto.password) {
      const saltOrRounds = 10;
      dataToUpdate.password = await bcrypt.hash(
        updateUserDto.password,
        saltOrRounds,
      );
    } else {
      delete dataToUpdate.password;
    }

    const updatedUser = await this.prisma.user.update({
      where: { id },
      data: dataToUpdate,
      // Não vamos incluir 'roles' aqui, pois a atualização de perfis será feita por endpoints dedicados
    });

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { password, ...result } = updatedUser;
    return result;
  }

  async remove(id: number) {
    const userExists = await this.prisma.user.findUnique({ where: { id } });
    if (!userExists) {
      throw new NotFoundException(`Usuário com ID #${id} não encontrado para exclusão.`);
    }
    // O onDelete: Cascade na relação User -> UserRole no schema.prisma
    // deve cuidar da remoção das associações em user_roles.
    await this.prisma.user.delete({
      where: { id },
    });
    return { message: `Usuário com ID #${id} deletado com sucesso.` };
  }

  // --- NOVOS MÉTODOS PARA ASSOCIAÇÃO DE PERFIS (ROLES) ---

  async assignRoleToUser(userId: number, roleId: number) {
    // 1. Verificar se o Usuário existe
    // Usamos o findOne deste próprio service, que já lança NotFoundException
    await this.findOne(userId); // Garante que o usuário existe

    // 2. Verificar se o Perfil (Role) existe
    // Usamos o findOne do RolesService injetado
    await this.rolesService.findOne(roleId); // Lançará NotFoundException se o perfil não existir

    // 3. Verificar se a associação já existe para evitar erro de chave duplicada
    const existingAssociation = await this.prisma.userRole.findUnique({
      where: {
        user_id_role_id: { // Nome do índice/chave primária composta no schema.prisma
          user_id: userId,
          role_id: roleId,
        },
      },
    });

    if (existingAssociation) {
      throw new ConflictException('Este perfil já está atribuído a este usuário.');
    }

    // 4. Criar a associação na tabela user_roles
    return this.prisma.userRole.create({
      data: {
        user_id: userId,
        role_id: roleId,
      },
      include: { // Opcional: retornar dados relacionados para confirmação
        user: { // Selecionar campos específicos do usuário para não expor a senha
          select: { id: true, name: true, email: true }
        },
        role: true,
      },
    });
  }

  async removeRoleFromUser(userId: number, roleId: number) {
    // 1. Verificar se a associação existe antes de tentar deletar
    const association = await this.prisma.userRole.findUnique({
      where: {
        user_id_role_id: {
          user_id: userId,
          role_id: roleId,
        },
      },
    });

    if (!association) {
      throw new NotFoundException(
        'Associação entre este usuário e perfil não encontrada para remoção.',
      );
    }

    // 2. Remover a associação
    return this.prisma.userRole.delete({
      where: {
        user_id_role_id: {
          user_id: userId,
          role_id: roleId,
        },
      },
    });
  }
}