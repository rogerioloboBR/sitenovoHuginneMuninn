// src/users/users.controller.ts
import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Patch,
  Delete,
  ParseIntPipe,
  HttpCode,
  HttpStatus,
  UseGuards, // 👈 1. Importe UseGuards
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport'; // 👈 2. Importe AuthGuard
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { AssignRoleDto } from './dto/assign-role.dto';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

@ApiTags('Users')
@Controller('users')
// Se quiser proteger TODAS as rotas deste controller, coloque o @UseGuards aqui em cima:
// @UseGuards(AuthGuard('jwt'))
@ApiBearerAuth('access-token')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post() // A rota de criação de usuário geralmente é pública
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @UseGuards(AuthGuard('jwt')) // 👈 3. Protegendo apenas esta rota
  @Get()
  findAll() {
    return this.usersService.findAll();
  }

  @UseGuards(AuthGuard('jwt')) // Exemplo: protegendo também o findOne
  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.usersService.findOne(id);
  }

  @UseGuards(AuthGuard('jwt')) // Exemplo: protegendo também o update
  @Patch(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateUserDto: UpdateUserDto,
  ) {
    return this.usersService.update(id, updateUserDto);
  }

  @UseGuards(AuthGuard('jwt')) // Exemplo: protegendo também o delete
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param('id', ParseIntPipe) id: number) {
    await this.usersService.remove(id);
  }

  // --- ENDPOINTS PARA ASSOCIAÇÃO DE PERFIS (ROLES) ---
  // Estes também devem ser protegidos, provavelmente apenas para admins
  @UseGuards(AuthGuard('jwt'))
  @Post(':userId/roles')
  assignRoleToUser(
    @Param('userId', ParseIntPipe) userId: number,
    @Body() assignRoleDto: AssignRoleDto,
  ) {
    return this.usersService.assignRoleToUser(userId, assignRoleDto.roleId);
  }

  @UseGuards(AuthGuard('jwt'))
  @Delete(':userId/roles/:roleId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async removeRoleFromUser(
    @Param('userId', ParseIntPipe) userId: number,
    @Param('roleId', ParseIntPipe) roleId: number,
  ) {
    await this.usersService.removeRoleFromUser(userId, roleId);
  }
}
