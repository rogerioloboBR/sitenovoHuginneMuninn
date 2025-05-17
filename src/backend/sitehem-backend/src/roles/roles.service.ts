// src/roles/roles.service.ts
import {
    Injectable,
    NotFoundException,
    ConflictException,
  } from '@nestjs/common';
  import { PrismaService } from '../prisma/prisma.service'; // Ajuste o caminho se necessário
  import { CreateRoleDto } from './dto/create-role.dto';
  import { UpdateRoleDto } from './dto/update-role.dto';
  import { Role } from '@prisma/client'; // Importe o tipo Role gerado pelo Prisma
  
  @Injectable()
  export class RolesService {
    constructor(private prisma: PrismaService) {}
  
    async create(createRoleDto: CreateRoleDto): Promise<Role> {
      // Verifica se já existe um perfil com o mesmo nome
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
      return this.prisma.role.findMany();
    }
  
    async findOne(id: number): Promise<Role> {
      const role = await this.prisma.role.findUnique({
        where: { id },
      });
  
      if (!role) {
        throw new NotFoundException(`Perfil com ID #${id} não encontrado.`);
      }
      return role;
    }
  
    async update(id: number, updateRoleDto: UpdateRoleDto): Promise<Role> {
      // Primeiro, garanta que o perfil que se quer atualizar existe
      const roleToUpdate = await this.prisma.role.findUnique({ where: { id } });
      if (!roleToUpdate) {
        throw new NotFoundException(
          `Perfil com ID #${id} não encontrado para atualização.`,
        );
      }
  
      // Se o nome estiver sendo atualizado, verifique se o novo nome já não está em uso por outro perfil
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
      // Garante que o perfil existe antes de tentar deletar
      const roleExists = await this.prisma.role.findUnique({ where: { id } });
      if (!roleExists) {
        throw new NotFoundException(
          `Perfil com ID #${id} não encontrado para exclusão.`,
        );
      }
  
      return this.prisma.role.delete({
        where: { id },
      });
      // Alternativamente, você pode retornar uma mensagem ou void:
      // await this.prisma.role.delete({ where: { id } });
      // return { message: `Perfil com ID #${id} deletado com sucesso.` };
    }
  }