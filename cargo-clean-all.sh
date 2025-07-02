cargo-clean-all() {
  # Define o diretório base como o primeiro argumento, ou usa ~/Repositories por padrão.
  # Ou seja, se você rodar 'cargo-clean-all /meu/caminho', ele vai usar /meu/caminho. Se não passar nada, usa ~/Repositories.
  local base_dir="${1:-$HOME/Repositories}"

  # Variável para saber se algum projeto foi encontrado (usada para mensagem final).
  local found_any=false

  # Verifica se o comando 'cargo' está disponível no PATH.
  # Se não estiver, mostra uma mensagem de erro e encerra a função.
  if ! command -v cargo >/dev/null 2>&1; then
    echo "❌ Cargo não está instalado ou não está no PATH. Abortando."
    return 1
  fi

  # O comando 'find' faz o seguinte:
  # - Percorre recursivamente o diretório base ($base_dir)
  # - Ignora diretórios ocultos (os que começam com '.')
  # - Procura arquivos chamados 'Cargo.toml'
  # - Para cada 'Cargo.toml', executa 'awk' para verificar se contém a seção [workspace] OU [package]
  #   (permitindo espaços antes de '[workspace]' ou '[package]')
  # - Só imprime o caminho se for um projeto válido
  find "$base_dir" \
    -type d -name '.*' -prune -false -o \ # ignora diretórios ocultos
    -type f -name Cargo.toml \            # procura arquivos Cargo.toml
    -exec awk '/^\s*\[(workspace|package)\]/ { found=1; exit } END { exit !found }' {} \; -print | # verifica se são projetos/workspaces válidos
    while read -r cargo_toml; do
      found_any=true                      # Marca que encontrou pelo menos um projeto
      dir=$(dirname "$cargo_toml")        # Obtém o diretório onde está o Cargo.toml

      # Verifica se tem permissão de escrita no diretório antes de tentar limpar.
      if [ ! -w "$dir" ]; then
        echo "🚫 Sem permissão de escrita em: $dir (pulado)"
        echo "-----------------------------------------------"
        continue
      fi

      # Só executa a limpeza se existir o diretório 'target' (onde ficam os arquivos compilados).
      if [ -d "$dir/target" ]; then
        # Identifica se é workspace ou package, para ajustar a mensagem.
        if grep -q '^\s*\[workspace\]' "$cargo_toml"; then
          tipo="workspace"
        elif grep -q '^\s*\[package\]' "$cargo_toml"; then
          tipo="package"
        else
          tipo="desconhecido"
        fi

        # Mostra no terminal o que está fazendo.
        echo "🧹 Limpando Cargo $tipo: $dir"
        # Executa 'cargo clean' dentro do diretório do projeto.
        (cd "$dir" && cargo clean)
        # Verifica se o comando foi bem sucedido.
        if [ $? -eq 0 ]; then
          echo "✅ Finalizado: $dir"
        else
          echo "❌ Falha ao limpar: $dir"
        fi
      else
        # Se não existe o diretório 'target', provavelmente nunca foi feito um build.
        echo "⚠️  Nenhum diretório target encontrado em: $dir (pulado)"
      fi
      # Linha separadora para facilitar a leitura no terminal.
      echo "-----------------------------------------------"
    done

  # Mensagem final: se nenhum projeto foi encontrado, avisa o usuário.
  if ! $found_any; then
    echo "ℹ️  Nenhum projeto Cargo com [workspace] ou [package] encontrado em $base_dir."
  else
    echo "🎉 Todos os projetos Cargo foram limpos!"
  fi
}