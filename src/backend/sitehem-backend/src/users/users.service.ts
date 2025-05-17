import {
  Injectable,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

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
        // is_active, email_verified_at já têm defaults no schema Prisma ou são opcionais
      },
    });

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { password, ...result } = user;
    return result;
  }

  async findAll() {
    return this.prisma.user.findMany({
      select: {
        id: true,
        name: true,
        email: true,
        email_verified_at: true,
        is_active: true,
        created_at: true,
        updated_at: true,
        // Adicione aqui outros campos que você queira retornar, exceto a senha
      },
    });
  }

  async findOne(id: number) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        email: true,
        email_verified_at: true,
        is_active: true,
        created_at: true,
        updated_at: true,
      },
    });
    if (!user) {
      throw new NotFoundException(`Usuário com ID #${id} não encontrado.`);
    }
    return user;
  }
   async findOneByEmailForAuth(email: string) {
    // Este método é específico para autenticação e retorna a senha
    const user = await this.prisma.user.findUnique({
      where: { email },
    });
    if (!user) {
      return null; // Ou throw NotFoundException se preferir que o auth service lide com isso
    }
    return user; // Retorna o usuário completo, incluindo o hash da senha
  }

  async update(id: number, updateUserDto: UpdateUserDto) {
    const userToUpdate = await this.prisma.user.findUnique({ where: { id } });
    if (!userToUpdate) {
      throw new NotFoundException(`Usuário com ID #${id} não encontrado para atualização.`);
    }

    // Se o email estiver sendo atualizado, verifique se o novo email já existe para outro usuário
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
      // Garante que a senha não seja definida como null ou undefined se não for passada
      delete dataToUpdate.password;
    }

    const updatedUser = await this.prisma.user.update({
      where: { id },
      data: dataToUpdate,
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

    await this.prisma.user.delete({
      where: { id },
    });
    // Você pode retornar void, uma mensagem, ou o usuário deletado (sem a senha)
    return { message: `Usuário com ID #${id} deletado com sucesso.` };
  }
}