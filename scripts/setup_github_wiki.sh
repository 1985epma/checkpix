#!/bin/bash
# Script para criar a wiki do GitHub a partir da pasta wiki/ local usando gh CLI

set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI não está instalado. Veja https://cli.github.com/"
  exit 1
fi

REPO=$(basename $(git rev-parse --show-toplevel))

echo "Criando wiki para o repositório $REPO (requer autenticação gh)..."

# Cria um repositório temporário para o conteúdo da wiki
tmpdir=$(mktemp -d)
git clone --depth=1 "$(git config --get remote.origin.url)" "$tmpdir/wiki-repo"
cd "$tmpdir/wiki-repo"

git checkout --orphan gh-pages || true
rm -rf *
cp -r "$(git rev-parse --show-toplevel)/wiki/"* .
git add .
git commit -m "Init wiki from repo"
git push origin HEAD:refs/heads/wiki || true

echo "Wiki criado/atualizado na branch 'wiki' (verifique no GitHub)."
