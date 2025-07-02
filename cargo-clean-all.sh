cargo-clean-all() {
  # Define o diretório base como o primeiro argumento, ou usa ~/Repositories por padrão.
  local base_dir="${1:-$HOME/Repositories}"
  # Variável para saber se algum workspace foi encontrado (usada para mensagem final).
  local found_any=false

  # Verifica se o comando 'cargo' está disponível no PATH.
  if ! command -v cargo >/dev/null 2>&1; then
    echo "❌ Cargo não está instalado ou não está no PATH. Abortando."
    return 1
  fi

  # O comando 'find' abaixo faz o seguinte:
  # - Percorre recursivamente o diretório base.
  # - Ignora diretórios ocultos (aqueles que começam com '.').
  # - Procura arquivos chamados 'Cargo.toml'.
  # - Para cada 'Cargo.toml', executa 'awk' para verificar se contém a seção [workspace]
  #   (permitindo espaços antes do '[workspace]').
  # - Só imprime o caminho se for um workspace válido.
  find "$base_dir" \
    -type d -name '.*' -prune -false -o \
    -type f -name Cargo.toml \
    -exec awk '/^\s*\[workspace\]/ { found=1; exit } END { exit !found }' {} \; -print |
    while read -r cargo_toml; do
      # Marca que encontrou pelo menos um workspace.
      found_any=true
      # Obtém o diretório onde está o 'Cargo.toml'
      dir=$(dirname "$cargo_toml")

      # Verifica se tem permissão de escrita no diretório antes de tentar limpar.
      if [ ! -w "$dir" ]; then
        echo "🚫 Sem permissão de escrita em: $dir (pulado)"
        echo "-----------------------------------------------"
        continue
      fi

      # Só executa a limpeza se existir o diretório 'target' (onde ficam os arquivos compilados).
      if [ -d "$dir/target" ]; then
        echo "🧹 Limpando workspace Cargo: $dir"
        # Executa 'cargo clean' dentro do diretório do workspace.
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

  # Mensagem final: se nenhum workspace foi encontrado, avisa o usuário.
  if ! $found_any; then
    echo "ℹ️  Nenhum workspace Cargo com [workspace] encontrado em $base_dir."
  else
    echo "🎉 Todos os workspaces Cargo foram limpos!"
  fi
}