// src/permissions/permissions.controller.ts
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
  } from '@nestjs/common';
  import { PermissionsService } from './permissions.service';
  import { CreatePermissionDto } from './dto/create-permission.dto';
  import { UpdatePermissionDto } from './dto/update-permission.dto';
  // Futuramente, adicionaremos decorators para Swagger e para proteção de rotas aqui.
  
  @Controller('permissions') // Define o prefixo da rota base como /permissions
  export class PermissionsController {
    constructor(private readonly permissionsService: PermissionsService) {}
  
    @Post()
    create(@Body() createPermissionDto: CreatePermissionDto) {
      return this.permissionsService.create(createPermissionDto);
    }
  
    @Get()
    findAll() {
      return this.permissionsService.findAll();
    }
  
    @Get(':id')
    findOne(@Param('id', ParseIntPipe) id: number) {
      return this.permissionsService.findOne(id);
    }
  
    @Patch(':id')
    update(
      @Param('id', ParseIntPipe) id: number,
      @Body() updatePermissionDto: UpdatePermissionDto,
    ) {
      return this.permissionsService.update(id, updatePermissionDto);
    }
  
    @Delete(':id')
    @HttpCode(HttpStatus.NO_CONTENT) // Retorna 204 No Content em caso de sucesso
    async remove(@Param('id', ParseIntPipe) id: number) {
      await this.permissionsService.remove(id);
      // Nenhum corpo de resposta é enviado devido ao HttpStatus.NO_CONTENT
    }
  }