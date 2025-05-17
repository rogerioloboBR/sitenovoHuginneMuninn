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
  import { RolesService } from './roles.service';
  import { CreateRoleDto } from './dto/create-role.dto';
  import { UpdateRoleDto } from './dto/update-role.dto';
  // Futuramente, adicionaremos decorators para Swagger e para proteção de rotas aqui.
  
  @Controller('roles') // Define o prefixo da rota base como /roles
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
      // ParseIntPipe converte o parâmetro 'id' da URL para um número
      // e lança uma exceção se não for um inteiro válido.
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
    @HttpCode(HttpStatus.NO_CONTENT) // Retorna 204 No Content em caso de sucesso
    async remove(@Param('id', ParseIntPipe) id: number) {
      await this.rolesService.remove(id);
      // Com HttpStatus.NO_CONTENT, nenhum corpo de resposta é enviado.
      // Se você quiser enviar a mensagem de sucesso do service, remova @HttpCode
      // e modifique o service para retornar o objeto da mensagem.
    }
  }