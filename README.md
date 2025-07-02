# cargo-clean-all

Função Bash para limpar todos os workspaces Cargo encontrados recursivamente sob um diretório base, ignorando diretórios ocultos e fornecendo mensagens visuais informativas.

---

## ⚠️ Aviso de uso

> **ATENÇÃO:**  
> Use este script por sua conta e risco.  
> Certifique-se de compreender o que ele faz antes de executar, principalmente em ambientes onde múltiplos projetos compartilham dependências ou arquivos importantes.

---

## ✨ Funcionalidades

- **Busca recursiva:** Procura recursivamente por todos os arquivos `Cargo.toml` sob o diretório base informado, ignorando diretórios ocultos (nomes iniciados por ponto).
- **Limpa apenas workspaces:** Executa `cargo clean` apenas nos diretórios onde o `Cargo.toml` possui a seção `[workspace]`.
- **Valida existência do diretório `target`:** Só executa a limpeza se o diretório `target` existir, evitando comandos desnecessários.
- **Feedback visual:** Usa emojis para indicar ações, sucessos, falhas e avisos.
- **Flexibilidade:** Permite passar o diretório base como argumento; se não informado, usa `~/Repositories`.
- **Checagem de dependência:** Verifica se o comando `cargo` está instalado e acessível no PATH antes de iniciar.

---

## 🚀 Instalação

1. Copie o conteúdo do script `cargo-clean-all.sh` para seu arquivo de configuração do terminal (`~/.bashrc`, `~/.zshrc` etc).
2. Reinicie o terminal ou execute `source ~/.bashrc` (ou `source ~/.zshrc`).

---

## 🛠️ Uso

```bash
cargo-clean-all [diretorio_base]
```

- Se `diretorio_base` não for informado, será usado `~/Repositories` por padrão.
- O script busca recursivamente por workspaces Cargo (projetos com `[workspace]` no `Cargo.toml`) dentro dessa pasta e todas as suas subpastas, ignorando diretórios ocultos.
- Exemplo para rodar na pasta padrão:
  ```bash
  cargo-clean-all
  ```
- Exemplo para rodar em outro diretório:
  ```bash
  cargo-clean-all ~/meus-projetos
  ```

---

## 📋 O que o script faz em cada workspace?

- Exibe o caminho do diretório do workspace.
- Limpa arquivos de build com `cargo clean` caso o diretório `target` exista.
- Mostra mensagens de sucesso ou falha para cada workspace.
- Se não houver `target` no workspace, mostra aviso.
- Se o comando `cargo` não estiver instalado, aborta.

---

## 🧹 Exemplo de saída

```
🧹 Cleaning Cargo workspace: /home/user/Projects/rust-monorepo
✅ Done: /home/user/Projects/rust-monorepo
-----------------------------------------------
⚠️  No target directory found in: /home/user/Projects/empty-workspace (skipped)
-----------------------------------------------
🎉 All Cargo workspaces cleaned!
```

---

## 🐞 Possíveis limitações

- Diretórios ocultos aninhados podem não ser completamente ignorados em casos muito específicos.
- Só remove arquivos gerados por `cargo build` (diretório `target`).
- Assume que todos os workspaces usam a convenção padrão do Cargo.
- Não limpa workspaces sem um diretório `target`.

---

## 📄 Licença

The GNU General Public License v3.0

---