#!/bin/bash

# Script para automatizar a criação de uma feature branch no Git

echo "---------------------------------------------------------------------"
echo "🚀 Assistente para Criação de Nova Feature Branch"
echo "---------------------------------------------------------------------"

# 1. Pergunta ao usuário qual é a branch base
read -p "Qual é a branch base da qual você quer criar a nova feature (ex: main, develop)? [main]: " BASE_BRANCH_INPUT
# Define 'main' como padrão se nada for inserido, e converte para minúsculas
BASE_BRANCH_NORMALIZED=$(echo "${BASE_BRANCH_INPUT:-main}" | tr '[:upper:]' '[:lower:]')

# 2. Pergunta o nome da feature
read -p "Qual é o nome descritivo para a nova feature? (ex: Autenticacao de Usuario): " FEATURE_NAME_INPUT

# Valida se o nome da feature foi fornecido
if [ -z "$FEATURE_NAME_INPUT" ]; then
  echo "❌ Erro: O nome da feature não pode ser vazio."
  exit 1
fi

# Cria um "slug" amigável para o nome da branch a partir do nome da feature
# Converte para minúsculas, substitui espaços e caracteres não alfanuméricos por '-', remove múltiplos hífens, remove hífens no início/fim
FEATURE_NAME_SLUG=$(echo "$FEATURE_NAME_INPUT" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-zA-Z0-9]/-/g' -e 's/-\{2,\}/-/g' -e 's/^-//' -e 's/-$//')

# Valida se o slug da feature não ficou vazio após a sanitização (ex: se o usuário digitou apenas "!!!")
if [ -z "$FEATURE_NAME_SLUG" ]; then
  echo "❌ Erro: O nome da feature resultou em um nome de branch inválido após a sanitização."
  echo "   Por favor, use letras, números ou hífens para o nome da feature."
  exit 1
fi

# Define o prefixo e o nome final da branch
BRANCH_PREFIX="feature/"
BRANCH_NAME="${BRANCH_PREFIX}${FEATURE_NAME_SLUG}"

echo ""
echo "---------------------------------------------------------------------"
echo "🔍 Resumo da Operação:"
echo "---------------------------------------------------------------------"
echo "Branch Base Selecionada: ${BASE_BRANCH_NORMALIZED}"
echo "Nome da Feature Informado: \"${FEATURE_NAME_INPUT}\""
echo "Nome da Branch a ser Criada: ${BRANCH_NAME}"
echo "---------------------------------------------------------------------"
echo ""

# Confirmação do usuário
read -p "Pressione Enter para continuar com estas configurações ou Ctrl+C para cancelar..."

# 3. Mudar para a branch base
echo ""
echo "🔄 Trocando para a branch '${BASE_BRANCH_NORMALIZED}'..."
if ! git checkout "${BASE_BRANCH_NORMALIZED}"; then
  echo "❌ Erro ao tentar trocar para a branch '${BASE_BRANCH_NORMALIZED}'."
  echo "   Verifique se a branch existe localmente e se não há alterações não commitadas que impeçam a troca."
  exit 1
fi

# 4. Atualizar a branch base
echo "📥 Puxando as últimas atualizações para '${BASE_BRANCH_NORMALIZED}' do repositório 'origin'..."
if ! git pull origin "${BASE_BRANCH_NORMALIZED}"; then
  echo "⚠️  Aviso: Falha ao puxar atualizações para '${BASE_BRANCH_NORMALIZED}'."
  echo "   Pode haver conflitos, a branch remota 'origin/${BASE_BRANCH_NORMALIZED}' pode não existir ou você pode estar offline."
  echo "   Continuando com a versão local de '${BASE_BRANCH_NORMALIZED}'..."
  # Não sair do script aqui, permitir criação a partir da local, mas avisar.
fi

# 5. Criar a nova feature branch a partir da branch base atualizada ou fazer checkout se já existir
echo "🌿 Verificando/Criando a branch '${BRANCH_NAME}'..."
if git rev-parse --verify "${BRANCH_NAME}" >/dev/null 2>&1; then
  echo "↪️  A branch '${BRANCH_NAME}' já existe localmente. Fazendo checkout..."
  if ! git checkout "${BRANCH_NAME}"; then
    echo "❌ Erro fatal ao tentar fazer checkout para a branch '${BRANCH_NAME}' existente."
    exit 1
  fi
  echo "✅ Checkout para a branch '${BRANCH_NAME}' existente realizado com sucesso."
  echo "   Certifique-se de que esta é a branch correta e que seu estado é o esperado."
  # Opcional: Perguntar se deseja puxar atualizações para a feature branch existente
  # read -p "Deseja tentar atualizar a branch '${BRANCH_NAME}' do repositório remoto (git pull)? (s/N): " PULL_EXISTING_BRANCH
  # if [[ "$PULL_EXISTING_BRANCH" =~ ^[Ss]$ ]]; then
  #   echo "📥 Puxando atualizações para '${BRANCH_NAME}'..."
  #   if ! git pull origin "${BRANCH_NAME}"; then
  #     echo "⚠️  Aviso: Falha ao puxar atualizações para a branch existente '${BRANCH_NAME}'."
  #   fi
  # fi
else
  echo "🌱 Criando e trocando para a nova branch '${BRANCH_NAME}' a partir de '${BASE_BRANCH_NORMALIZED}'..."
  if ! git checkout -b "${BRANCH_NAME}"; then
    echo "❌ Erro ao criar a branch '${BRANCH_NAME}'."
    exit 1
  fi
  echo "✅ Branch '${BRANCH_NAME}' criada com sucesso."
fi


# 6. Fazer o push da branch para o repositório remoto e configurar o upstream
# Isso é útil tanto para branches novas quanto para existentes que talvez não tenham um upstream configurado.
echo "📤 Enviando a branch '${BRANCH_NAME}' para o repositório remoto 'origin' e configurando upstream..."
if ! git push -u origin "${BRANCH_NAME}"; then
  echo "⚠️  Aviso: Falha ao fazer push da branch '${BRANCH_NAME}' para o repositório remoto 'origin'."
  echo "   Isso pode acontecer se a branch já existe no remoto com histórico divergente, ou por problemas de permissão/conexão."
  echo "   Você talvez precise fazer o push manualmente ('git push origin ${BRANCH_NAME}') ou resolver conflitos."
  # Não sair do script, pois a branch local foi criada/acessada.
fi

echo ""
echo "---------------------------------------------------------------------"
CURRENT_BRANCH_FINAL=$(git symbolic-ref --short HEAD)
if [ "$CURRENT_BRANCH_FINAL" == "$BRANCH_NAME" ]; then
  echo "✅ Operação Concluída! Você está na branch: ${CURRENT_BRANCH_FINAL}"
else
  echo "⚠️ Atenção! A operação foi concluída, mas você não está na branch '${BRANCH_NAME}' como esperado."
  echo "   Branch atual: ${CURRENT_BRANCH_FINAL}. Verifique o console para possíveis erros."
fi
echo "---------------------------------------------------------------------"
echo ""
echo "👉 Próximos passos:"
echo "   1. Comece a desenvolver sua feature na branch '${BRANCH_NAME}'."
echo "   2. Faça commits regularmente: git add . && git commit -m \"Sua mensagem de commit\""
echo "   3. Faça push das suas alterações para o remoto: git push"
echo "   4. Quando a feature estiver pronta, abra um Pull Request (PR) no GitHub/GitLab/Bitbucket da branch '${BRANCH_NAME}' para a branch '${BASE_BRANCH_NORMALIZED}'."
echo "---------------------------------------------------------------------"

exit 0