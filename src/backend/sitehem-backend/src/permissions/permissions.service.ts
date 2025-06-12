// src/permissions/permissions.service.ts
import {
    Injectable,
    NotFoundException,
    ConflictException,
  } from '@nestjs/common';
  import { PrismaService } from '../prisma/prisma.service'; // Ajuste o caminho se necessário
  import { CreatePermissionDto } from './dto/create-permission.dto';
  import { UpdatePermissionDto } from './dto/update-permission.dto';
  import { Permission } from '@prisma/client'; // Importe o tipo Permission gerado pelo Prisma
  
  @Injectable()
  export class PermissionsService {
    constructor(private prisma: PrismaService) {}
  
    async create(createPermissionDto: CreatePermissionDto): Promise<Permission> {
      // Verifica se já existe uma permissão com o mesmo nome
      const existingPermission = await this.prisma.permission.findUnique({
        where: { name: createPermissionDto.name },
      });
  
      if (existingPermission) {
        throw new ConflictException(
          `Uma permissão com o nome '${createPermissionDto.name}' já existe.`,
        );
      }
  
      return this.prisma.permission.create({
        data: createPermissionDto,
      });
    }
  
    async findAll(): Promise<Permission[]> {
      return this.prisma.permission.findMany();
    }
  
    async findOne(id: number): Promise<Permission> {
      const permission = await this.prisma.permission.findUnique({
        where: { id },
      });
  
      if (!permission) {
        throw new NotFoundException(`Permissão com ID #${id} não encontrada.`);
      }
      return permission;
    }
  
    async update(
      id: number,
      updatePermissionDto: UpdatePermissionDto,
    ): Promise<Permission> {
      // Primeiro, garanta que a permissão que se quer atualizar existe
      const permissionToUpdate = await this.prisma.permission.findUnique({
        where: { id },
      });
      if (!permissionToUpdate) {
        throw new NotFoundException(
          `Permissão com ID #${id} não encontrada para atualização.`,
        );
      }
  
      // Se o nome da permissão estiver sendo atualizado,
      // verifique se o novo nome já não está em uso por outra permissão
      if (
        updatePermissionDto.name &&
        updatePermissionDto.name !== permissionToUpdate.name
      ) {
        const existingPermissionWithNewName =
          await this.prisma.permission.findUnique({
            where: { name: updatePermissionDto.name },
          });
        if (
          existingPermissionWithNewName &&
          existingPermissionWithNewName.id !== id
        ) {
          throw new ConflictException(
            `Uma permissão com o nome '${updatePermissionDto.name}' já existe.`,
          );
        }
      }
  
      return this.prisma.permission.update({
        where: { id },
        data: updatePermissionDto,
      });
    }
  
    async remove(id: number): Promise<Permission> {
      // Garante que a permissão existe antes de tentar deletar
      const permissionExists = await this.prisma.permission.findUnique({
        where: { id },
      });
      if (!permissionExists) {
        throw new NotFoundException(
          `Permissão com ID #${id} não encontrada para exclusão.`,
        );
      }
  
      return this.prisma.permission.delete({
        where: { id },
      });
    }
  }