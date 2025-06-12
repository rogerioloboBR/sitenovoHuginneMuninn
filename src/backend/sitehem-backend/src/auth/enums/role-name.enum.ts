// src/auth/enums/role-name.enum.ts

// Defina aqui os nomes exatos dos seus perfis como strings.
// Estes devem corresponder aos valores da coluna 'name' na sua tabela 'roles'.
export enum RoleName {
    Admin = 'admin', // Ou 'ADMIN', 'Administrador do sistema' - o que estiver no seu BD
    Customer = 'customer', // Ou 'CUSTOMER', 'Cliente da loja'
    Editor = 'editor',   // Ou 'EDITOR', 'Editor de Conteúdo'
    // Adicione outros perfis conforme necessário
  }
  