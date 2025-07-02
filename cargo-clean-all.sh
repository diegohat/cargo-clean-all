cargo-clean-all() {
  # Define o diretório base para buscar projetos Cargo (padrão: ~/Repositories)
  local base_dir="${1:-$HOME/Repositories}"
  # Variável para saber se encontrou algum projeto
  local found_any=false

  # Verifica se o comando 'cargo' está instalado e disponível no PATH
  if ! command -v cargo >/dev/null 2>&1; then
    echo "❌ Cargo não está instalado ou não está no PATH. Abortando."
    return 1
  fi

  # Procura por arquivos Cargo.toml em subdiretórios do base_dir, ignorando pastas ocultas
  find "$base_dir" \
    -type d -name '.*' -prune -false -o \  # Ignora diretórios ocultos
    -type f -name Cargo.toml \             # Procura arquivos Cargo.toml
    -exec awk '/^\s*\[(workspace|package)\]/ { found=1; exit } END { exit !found }' {} \; -print | \
    # Para cada arquivo Cargo.toml encontrado que contenha [workspace] ou [package]
    while read -r cargo_toml; do
      found_any=true
      dir=$(dirname "$cargo_toml")  # Pega o diretório do Cargo.toml

      # Verifica se tem permissão de escrita no diretório
      if [ ! -w "$dir" ]; then
        echo "🚫 Sem permissão de escrita em: $dir (pulado)"
        echo "-----------------------------------------------"
        continue
      fi

      # Verifica se existe a pasta 'target' (onde o Cargo guarda arquivos compilados)
      if [ -d "$dir/target" ]; then
        # Descobre se é um workspace ou um package
        if grep -q '^\s*\[workspace\]' "$cargo_toml"; then
          tipo="workspace"
        elif grep -q '^\s*\[package\]' "$cargo_toml"; then
          tipo="package"
        else
          tipo="desconhecido"
        fi

        echo "🧹 Limpando Cargo $tipo: $dir"
        # Entra no diretório e executa 'cargo clean' para limpar arquivos de build
        (cd "$dir" && cargo clean)
        if [ $? -eq 0 ]; then
          echo "✅ Finalizado: $dir"
          echo "-----------------------------------------------"
        else
          echo "❌ Falha ao limpar: $dir"
          echo "-----------------------------------------------"
        fi
      fi
    done

  # Se não encontrou nenhum projeto, avisa o usuário
  if ! $found_any; then
    echo "ℹ️  Nenhum projeto Cargo com [workspace] ou [package] encontrado em $base_dir."
  else
    echo "🎉 Todos os projetos Cargo foram limpos!"
  fi
}