cargo-clean-all() {
  # Define o diretório base como o primeiro argumento, ou usa ~/Repositories por padrão.
  local base_dir="${1:-$HOME/Repositories}"

  # Variável para saber se algum projeto foi encontrado (usada para mensagem final).
  local found_any=false

  # Verifica se o comando 'cargo' está disponível no PATH.
  if ! command -v cargo >/dev/null 2>&1; then
    echo "❌ Cargo não está instalado ou não está no PATH. Abortando."
    return 1
  fi

  # Array para armazenar caminhos dos workspaces já processados
  local -a workspaces=()

  # Função auxiliar para checar se um caminho está dentro de algum workspace já processado
  is_within_workspace() {
    local path="$1"
    for ws in "${workspaces[@]}"; do
      case "$path" in
        "$ws"/*) return 0 ;;  # está dentro de um workspace já processado
      esac
    done
    return 1  # não está dentro de nenhum workspace já processado
  }

  # Busca todos os Cargo.toml válidos recursivamente, ignorando diretórios ocultos
  find "$base_dir" \
    -type d -name '.*' -prune -false -o \
    -type f -name Cargo.toml \
    -exec awk '/^\s*\[(workspace|package)\]/ { found=1; exit } END { exit !found }' {} \; -print |
  while read -r cargo_toml; do
    dir=$(dirname "$cargo_toml")

    # Ignora se já está dentro de um workspace processado
    if is_within_workspace "$dir"; then
      continue
    fi

    # Marca que encontrou pelo menos um projeto
    found_any=true

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
        # Adiciona o caminho do workspace ao array de workspaces processados
        workspaces+=("$dir")
      elif grep -q '^\s*\[package\]' "$cargo_toml"; then
        tipo="package"
      else
        tipo="desconhecido"
      fi

      echo "🧹 Limpando Cargo $tipo: $dir"
      (cd "$dir" && cargo clean)
      if [ $? -eq 0 ]; then
        echo "✅ Finalizado: $dir"
      else
        echo "❌ Falha ao limpar: $dir"
      fi
    else
      echo "⚠️  Nenhum diretório target encontrado em: $dir (pulado)"
    fi
    echo "-----------------------------------------------"
  done

  if ! $found_any; then
    echo "ℹ️  Nenhum projeto Cargo com [workspace] ou [package] encontrado em $base_dir."
  else
    echo "🎉 Todos os projetos Cargo foram limpos!"
  fi
}