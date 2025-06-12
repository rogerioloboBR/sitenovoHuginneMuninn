#!/bin/bash

# Script para automatizar a criação de Pull Requests no GitHub, guiando o usuário.

# --- Funções Auxiliares ---
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# --- Início do Script ---
echo "---------------------------------------------------------------------"
echo "🚀 Assistente para Criação de Pull Request no GitHub"
echo "---------------------------------------------------------------------"

# 1. Verificar se está em um repositório Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ Erro: Este script deve ser executado dentro de um repositório Git."
  exit 1
fi

# 2. Verificar se a CLI 'gh' está instalada e autenticada
if ! command_exists gh; then
  echo "❌ Erro: A CLI do GitHub ('gh') não foi encontrada. Por favor, instale-a: https://cli.github.com/"
  exit 1
fi

# Verifica o status da autenticação e oferece login se necessário
if ! gh auth status >/dev/null 2>&1; then
  echo "⚠️  Aviso: Você não parece estar autenticado na CLI do GitHub ('gh')."
  read -p "Deseja tentar autenticar agora com 'gh auth login'? (S/n): " ATTEMPT_AUTH_ANSWER
  ATTEMPT_AUTH_ANSWER_NORMALIZED=${ATTEMPT_AUTH_ANSWER:-S} # Default para Sim

  if [[ "$ATTEMPT_AUTH_ANSWER_NORMALIZED" =~ ^[Ss]$ ]]; then
    echo "ℹ️  Iniciando o processo de autenticação do 'gh'. Siga as instruções que aparecerão na tela."
    echo "   (Isso pode abrir seu navegador ou pedir para você colar um código)."
    if gh auth login; then # gh auth login é interativo
      echo "✅ Autenticação com 'gh' parece ter sido bem-sucedida."
      # Re-verificar o status para ter certeza
      if ! gh auth status >/dev/null 2>&1; then
        echo "❌ Erro Pós-Autenticação: 'gh auth login' parece ter sido concluído, mas 'gh auth status' ainda indica um problema."
        echo "   Por favor, verifique sua configuração 'gh' manualmente ou tente 'gh auth refresh'."
        exit 1
      else
        echo "✅ Autenticação confirmada com 'gh auth status'."
      fi
    else
      echo "❌ Erro: O processo de 'gh auth login' falhou ou foi cancelado."
      echo "   Você precisa estar autenticado para continuar. Tente executar 'gh auth login' manualmente."
      exit 1
    fi
  else
    echo "🛑 Operação cancelada. Você precisa estar autenticado no 'gh' para criar um Pull Request."
    exit 1
  fi
else
  echo "✅ CLI 'gh' encontrada e você já está autenticado."
fi

# 3. Obter a branch atual
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
if [ -z "$CURRENT_BRANCH" ]; then
  echo "❌ Erro: Não foi possível determinar a branch atual."
  exit 1
fi
echo "ℹ️ Branch atual (origem do PR): ${CURRENT_BRANCH}"

# Impedir PR de branches principais comuns
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" || "$CURRENT_BRANCH" == "develop" ]]; then
  echo "❌ Erro: Você está na branch '${CURRENT_BRANCH}'. Pull Requests devem ser criados a partir de feature branches."
  echo "   Por favor, mude para a sua feature branch antes de continuar."
  exit 1
fi

# 4. Verificar status da branch e push para 'origin'
echo "🔄 Verificando status da branch '${CURRENT_BRANCH}' e sincronização com 'origin'..."
git remote update origin --prune >/dev/null 2>&1 # Atualiza o conhecimento local dos remotes

LOCAL_HASH=$(git rev-parse "$CURRENT_BRANCH")
REMOTE_HASH=$(git rev-parse "origin/$CURRENT_BRANCH" 2>/dev/null)

if [ -z "$REMOTE_HASH" ]; then
  echo "⚠️  Aviso: A branch '${CURRENT_BRANCH}' não parece existir no repositório remoto 'origin'."
  read -p "Deseja fazer push e definir upstream para 'origin/${CURRENT_BRANCH}' agora? (S/n): " PUSH_NEW_BRANCH
  PUSH_NEW_BRANCH_ANSWER=${PUSH_NEW_BRANCH:-S}
  if [[ "$PUSH_NEW_BRANCH_ANSWER" =~ ^[Ss]$ ]]; then
    if ! git push --set-upstream origin "$CURRENT_BRANCH"; then
      echo "❌ Erro ao fazer push da branch. Verifique as mensagens de erro do Git."
      exit 1
    fi
    echo "✅ Branch '${CURRENT_BRANCH}' enviada para 'origin'."
    REMOTE_HASH=$(git rev-parse "origin/$CURRENT_BRANCH") # Atualiza o remote hash
  else
    echo "🛑 Operação cancelada. É necessário fazer push da branch antes de criar um PR."
    exit 1
  fi
elif [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
  COMMITS_LOCAL_ONLY=$(git rev-list --count "origin/$CURRENT_BRANCH..HEAD")
  COMMITS_REMOTE_ONLY=$(git rev-list --count "HEAD..origin/$CURRENT_BRANCH")

  if [ "$COMMITS_REMOTE_ONLY" -gt 0 ]; then
     echo "⚠️  Aviso: Sua branch local '${CURRENT_BRANCH}' está ${COMMITS_REMOTE_ONLY} commit(s) atrás da branch remota 'origin/${CURRENT_BRANCH}'."
     read -p "Deseja executar 'git pull origin ${CURRENT_BRANCH}' para atualizar? (S/n): " PULL_BRANCH_ANSWER
     PULL_BRANCH_ANSWER=${PULL_BRANCH_ANSWER:-S}
     if [[ "$PULL_BRANCH_ANSWER" =~ ^[Ss]$ ]]; then
        if ! git pull origin "$CURRENT_BRANCH"; then
            echo "❌ Erro ao executar 'git pull'. Resolva os conflitos ou problemas e tente novamente."
            exit 1
        fi
        echo "✅ Branch local atualizada."
        # Recalcular commits locais após o pull
        COMMITS_LOCAL_ONLY=$(git rev-list --count "origin/$CURRENT_BRANCH..HEAD")
     else
        echo "🛑  Aviso: Continuar sem atualizar pode não ser o ideal. Sua branch local está desatualizada."
     fi
  fi

  # Verifica novamente se há commits locais para enviar após um possível pull
  if [ "$COMMITS_LOCAL_ONLY" -gt 0 ]; then
    echo "⚠️  Aviso: Você tem ${COMMITS_LOCAL_ONLY} commit(s) locais que não foram enviados para 'origin/${CURRENT_BRANCH}'."
    read -p "Deseja fazer 'git push origin ${CURRENT_BRANCH}' agora? (S/n): " PUSH_COMMITS_ANSWER
    PUSH_COMMITS_ANSWER=${PUSH_COMMITS_ANSWER:-S}
    if [[ "$PUSH_COMMITS_ANSWER" =~ ^[Ss]$ ]]; then
      if ! git push origin "$CURRENT_BRANCH"; then
        echo "❌ Erro ao fazer push dos commits. Verifique as mensagens de erro do Git."
        exit 1
      fi
      echo "✅ Commits enviados para 'origin/${CURRENT_BRANCH}'."
    else
      echo "🛑  Aviso: Seus últimos commits não foram enviados. O PR será baseado no estado atual da branch remota, o que pode não ser o que você deseja."
    fi
  fi
else
  echo "✅ Branch '${CURRENT_BRANCH}' está sincronizada com 'origin/${CURRENT_BRANCH}'."
fi


# 5. Coletar informações para o PR
#    Branch Alvo (Base)
read -p "Qual é a branch alvo (base) para este Pull Request? (ex: main, develop) [main]: " TARGET_BRANCH_INPUT
TARGET_BRANCH=$(echo "${TARGET_BRANCH_INPUT:-main}" | tr '[:upper:]' '[:lower:]')

# Tenta buscar a branch alvo do origin para ter o ponto de merge-base mais atualizado
echo "ℹ️  Tentando buscar a branch alvo '${TARGET_BRANCH}' do 'origin' para referência de commits..."
if ! git fetch origin "${TARGET_BRANCH}" >/dev/null 2>&1; then
    echo "⚠️  Aviso: Não foi possível buscar a branch '${TARGET_BRANCH}' do 'origin'."
    echo "   A lista de commits recentes no corpo do PR pode ser menos precisa ou baseada apenas nos commits locais."
fi


#    Título do PR
# Sugere um título removendo prefixos comuns e capitalizando
DEFAULT_PR_TITLE=$(echo "$CURRENT_BRANCH" | sed -E 's#^(feature|feat|fix|hotfix|chore|bug)/##I' | sed -E 's/[-_]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
read -p "Título do Pull Request [${DEFAULT_PR_TITLE}]: " PR_TITLE
PR_TITLE=${PR_TITLE:-$DEFAULT_PR_TITLE}

#    Corpo do PR (usando editor de texto)
PR_BODY_FILE=$(mktemp "${TMPDIR:-/tmp}/gh_pr_body.XXXXXX.md")
{
    echo "" # Linha em branco inicial
    echo "# Preencha o corpo do Pull Request abaixo."
    echo "# Linhas começando com '#' serão ignoradas pelo 'gh pr create' se não forem parte de um cabeçalho Markdown."
    echo "# Salve e feche o editor para continuar."
    echo ""
    echo "## O que este PR faz?"
    echo "- "
    echo ""
    echo "## Como testar?"
    echo "1. "
    echo ""
    echo "## Checklist (Opcional):"
    echo "- [ ] Testes unitários adicionados/atualizados."
    echo "- [ ] Documentação atualizada."
    echo "- [ ] Testado manualmente em ambiente de desenvolvimento."
    echo ""
    echo "## Commits Recentes nesta Branch (para referência):"
    # Encontra o ponto comum com a branch alvo (se existir remotamente e foi buscada)
    # ou pega os últimos N commits da branch atual.
    MERGE_BASE=$(git merge-base "origin/${TARGET_BRANCH}" HEAD 2>/dev/null)
    if [ -n "$MERGE_BASE" ]; then
        git log --pretty=format:"- %s (%h)" "${MERGE_BASE}"..HEAD >> "$PR_BODY_FILE"
    else
        echo "# (Não foi possível determinar o ponto de merge com origin/${TARGET_BRANCH}, mostrando últimos 10 commits da branch atual)" >> "$PR_BODY_FILE"
        git log -10 --pretty=format:"- %s (%h)" HEAD >> "$PR_BODY_FILE"
    fi
    echo ""
} > "$PR_BODY_FILE"

# Determinar o editor
EDITOR_CMD=${EDITOR:-vi} # Default para vi se $EDITOR não estiver setado
echo "📝 Abrindo o editor ('${EDITOR_CMD}') para você escrever o corpo do PR..."
echo "   (Salve e feche o editor para continuar)"

if ${EDITOR_CMD} "${PR_BODY_FILE}"; then
    echo "✅ Corpo do PR editado."
    # O conteúdo do arquivo será usado diretamente pelo 'gh pr create --body-file'
else
    echo "❌ Erro ou cancelamento ao usar o editor. O corpo do PR não foi capturado."
    rm -f "${PR_BODY_FILE}"
    exit 1
fi

# 6. Mostrar resumo e pedir confirmação
echo "---------------------------------------------------------------------"
echo "📄 Resumo do Pull Request a ser criado:"
echo "---------------------------------------------------------------------"
echo "   De (Head Branch):   ${CURRENT_BRANCH}"
echo "   Para (Base Branch): ${TARGET_BRANCH}"
echo "   Título:             ${PR_TITLE}"
echo "   Corpo (do arquivo): ${PR_BODY_FILE} (Pré-visualização abaixo)"
echo "---------------------------------------------------------------------"
# Mostrar uma pré-visualização do corpo (removendo linhas de comentário que o script adicionou)
sed '/^# Preencha o corpo do Pull Request abaixo./d;/^# Linhas começando com .* ser(ã|a)o ignoradas pelo .*gh pr create.*/d;/^# Salve e feche o editor para continuar./d' "${PR_BODY_FILE}" | sed '/^## Commits Recentes nesta Branch (para referência):/,$s/^# (.*)/  \1/' # Tenta descomentar a lista de commits se ela foi comentada no template
echo "---------------------------------------------------------------------"
echo "   (O PR será aberto no navegador após a criação)"
echo "---------------------------------------------------------------------"
echo ""
read -p "Deseja continuar e criar este Pull Request no GitHub? (S/n): " CONFIRM_CREATE_PR
CONFIRM_CREATE_PR_ANSWER=${CONFIRM_CREATE_PR:-S}

if [[ ! "$CONFIRM_CREATE_PR_ANSWER" =~ ^[Ss]$ ]]; then
  echo "🛑 Criação do Pull Request cancelada pelo usuário."
  rm -f "${PR_BODY_FILE}"
  exit 0
fi

# 7. Criar o Pull Request com 'gh'
echo "🚀 Criando Pull Request no GitHub..."
if gh pr create --base "${TARGET_BRANCH}" --head "${CURRENT_BRANCH}" --title "${PR_TITLE}" --body-file "${PR_BODY_FILE}" --web; then
  echo "✅ Pull Request criado com sucesso e aberto no navegador!"
else
  echo "❌ Erro ao tentar criar o Pull Request com 'gh'. Verifique a saída acima."
  echo "   O arquivo com o corpo do PR foi: ${PR_BODY_FILE} (não foi deletado em caso de erro, para sua referência)."
  # Não deletar o PR_BODY_FILE em caso de erro para que o usuário possa reusar o texto.
  exit 1
fi

# Limpeza somente em caso de sucesso
rm -f "${PR_BODY_FILE}"

echo "---------------------------------------------------------------------"
echo "🏁 Assistente finalizado."
echo "---------------------------------------------------------------------"

exit 0