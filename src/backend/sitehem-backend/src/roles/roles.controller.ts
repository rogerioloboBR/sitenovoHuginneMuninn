import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  ParseIntPipe,
  HttpCode,
  HttpStatus,
  BadRequestException, // 👈 Importar BadRequestException (se ainda usar a validação manual)
} from '@nestjs/common';
import { RolesService } from './roles.service';
import { CreateRoleDto } from './dto/create-role.dto';
import { UpdateRoleDto } from './dto/update-role.dto';
import { AssignPermissionDto } from './dto/assign-permission.dto'; // 👈 Importar o DTO

@Controller('roles')
export class RolesController {
  constructor(private readonly rolesService: RolesService) {}

  @Post()
  create(@Body() createRoleDto: CreateRoleDto) {
    return this.rolesService.create(createRoleDto);
  }

  @Get()
  findAll() {
    return this.rolesService.findAll();
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.rolesService.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateRoleDto: UpdateRoleDto,
  ) {
    return this.rolesService.update(id, updateRoleDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param('id', ParseIntPipe) id: number) {
    await this.rolesService.remove(id);
  }

  // --- ENDPOINTS PARA ASSOCIAÇÃO DE PERMISSÕES ---

  @Get(':roleId/permissions')
  findPermissionsForRole(@Param('roleId', ParseIntPipe) roleId: number) {
    return this.rolesService.findPermissionsForRole(roleId);
  }

  @Post(':roleId/permissions')
  assignPermissionToRole(
    @Param('roleId', ParseIntPipe) roleId: number,
    @Body() assignPermissionDto: AssignPermissionDto, // 👈 Usar o DTO importado
  ) {
    // Com o DTO e o ValidationPipe global, a validação de permissionId
    // (se é número e não está vazio) já é feita automaticamente.
    // A validação manual com BadRequestException não é mais necessária aqui
    // se o DTO estiver corretamente configurado e o ValidationPipe global ativo.
    return this.rolesService.assignPermissionToRole(
      roleId,
      assignPermissionDto.permissionId,
    );
  }

  @Delete(':roleId/permissions/:permissionId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async removePermissionFromRole(
    @Param('roleId', ParseIntPipe) roleId: number,
    @Param('permissionId', ParseIntPipe) permissionId: number,
  ) {
    await this.rolesService.removePermissionFromRole(roleId, permissionId);
  }
}
