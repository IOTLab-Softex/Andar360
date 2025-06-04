#!/bin/bash

echo "====================================="
echo "        ASSISTENTE DE RELEASE        "
echo "====================================="

# Lista branches remotas disponíveis
echo "🔍 Buscando branches disponíveis..."
BRANCHES=($(git for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -v HEAD | sed 's|origin/||' | sort -u))

# Menu de branch
echo "📌 Selecione a branch para o release:"
select BRANCH in "${BRANCHES[@]}"; do
  if [[ -n "$BRANCH" ]]; then
    echo "✅ Branch selecionada: $BRANCH"
    break
  else
    echo "❌ Opção inválida. Tente novamente."
  fi
done

# Verifica se há alterações antes do checkout
if [[ -n $(git status --porcelain) ]]; then
  echo "⚠️ Existem alterações locais:"
  git status --short

  read -p "❓ Deseja fazer 'git add .' agora? (s/n): " DO_ADD
  if [[ "$DO_ADD" == "s" || "$DO_ADD" == "S" ]]; then
    git add .
    echo "✅ Arquivos adicionados."

    read -p "📝 Digite a mensagem de commit: " COMMIT_MSG
    git commit -m "$COMMIT_MSG"
    echo "✅ Commit feito com sucesso."
  else
    echo "⚠️ Continuando sem adicionar nem commitar."
  fi
fi

# Tenta trocar de branch
echo "🔄 Trocando para a branch $BRANCH..."
if ! git checkout $BRANCH; then
  echo "❌ Erro ao trocar de branch."
  exit 1
fi

# Puxa atualizações
echo "⬇️ Atualizando branch $BRANCH..."
git pull origin $BRANCH

# Menu de ações pós-checkout
while true; do
  echo ""
  echo "📋 MENU DE AÇÕES PARA '$BRANCH'"
  echo "1) Push branch"
  echo "2) git add ."
  echo "3) Commit"
  echo "4) Criar release (tag)"
  echo "5) Sair"
  read -p "Escolha uma opção [1-5]: " OPTION

  case $OPTION in
    1)
      echo "📤 Enviando branch '$BRANCH'..."
      git push origin $BRANCH
      ;;
    2)
      echo "📦 Adicionando todos os arquivos..."
      git add .
      ;;
    3)
      read -p "📝 Digite a mensagem de commit: " COMMIT_MSG
      git commit -m "$COMMIT_MSG"
      ;;
    4)
      read -p "🏷️ Digite a nova versão (ex: v1.0.6): " VERSION
      if [[ -z "$VERSION" ]]; then
        echo "❌ Versão inválida."
      else
        git tag $VERSION
        git push origin $VERSION
        echo "🎉 Tag '$VERSION' criada e enviada com sucesso."
      fi
      ;;
    5)
      echo "👋 Saindo..."
      break
      ;;
    *)
      echo "❌ Opção inválida."
      ;;
  esac
done
