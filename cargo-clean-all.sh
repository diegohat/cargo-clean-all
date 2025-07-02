cargo-clean-all() {
  # Diretório base padrão
  local base_dir="${1:-$HOME/Repositories}"
  local found_any=false

  # Checa se cargo está disponível
  if ! command -v cargo >/dev/null 2>&1; then
    echo "❌ Cargo não está instalado ou não está no PATH. Abortando."
    return 1
  fi

  # Lista de diretórios de workspaces já processados
  local -a workspaces=()

  # Primeiro, coleta todos os Cargo.toml válidos
  mapfile -t all_cargo_tomls < <(
    find "$base_dir" \
      -type d -name '.*' -prune -false -o \
      -type f -name Cargo.toml \
      -exec awk '/^\s*\[(workspace|package)\]/ { found=1; exit } END { exit !found }' {} \; -print
  )

  for cargo_toml in "${all_cargo_tomls[@]}"; do
    dir=$(dirname "$cargo_toml")

    # Se já está dentro de algum workspace, pula
    skip=false
    for ws in "${workspaces[@]}"; do
      case "$dir/" in
        "$ws/"* ) skip=true; break ;;
      esac
    done
    $skip && continue

    # Marca que encontrou pelo menos um projeto
    found_any=true

    # Se não pode escrever, avisa e pula
    if [ ! -w "$dir" ]; then
      echo "🚫 Sem permissão de escrita em: $dir (pulado)"
      echo "-----------------------------------------------"
      continue
    fi

    # Só executa a limpeza se existir o diretório 'target'
    if [ -d "$dir/target" ]; then
      if grep -q '^\s*\[workspace\]' "$cargo_toml"; then
        tipo="workspace"
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