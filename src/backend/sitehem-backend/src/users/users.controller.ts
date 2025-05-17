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
  HttpCode, // Para o status 204 no DELETE
  HttpStatus, // Para o status 204 no DELETE
} from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Get()
  findAll() {
    return this.usersService.findAll();
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.usersService.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateUserDto: UpdateUserDto,
  ) {
    return this.usersService.update(id, updateUserDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT) // Retorna status 204 No Content em vez de 200 OK com corpo
  async remove(@Param('id', ParseIntPipe) id: number) {
    await this.usersService.remove(id);
    // Não precisa retornar a mensagem explicitamente se usar @HttpCode(HttpStatus.NO_CONTENT)
    // Se quiser retornar a mensagem, remova @HttpCode e deixe o service retornar o objeto da mensagem.
  }
}